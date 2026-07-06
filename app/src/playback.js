/**
 * Drives BPM-synced region playback using the AudioContext clock (drift-free,
 * unlike setInterval/rAF timestamps) as the single source of truth for both
 * the metronome click schedule and the current-region calculation.
 */
export class Playback {
  constructor({ getRegions, getBpm, getLoop, getMetronomeOn, onRegionChange, onStop }) {
    this.getRegions = getRegions;
    this.getBpm = getBpm;
    this.getLoop = getLoop;
    this.getMetronomeOn = getMetronomeOn;
    this.onRegionChange = onRegionChange;
    this.onStop = onStop;

    this.audioCtx = null;
    this.playing = false;
    this.rafId = null;
    this.startTime = 0;
    this.currentIndex = -1;
    this.nextTickBeat = 0;
    this.lastBpm = null;
    this.scheduleAheadTime = 0.15;

    this._loop = this._loop.bind(this);
  }

  ensureAudioCtx() {
    if (!this.audioCtx) {
      this.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (this.audioCtx.state === "suspended") {
      this.audioCtx.resume();
    }
    return this.audioCtx;
  }

  /** Starts playback from a given beat offset (0 = the very first region). */
  start(fromBeat = 0) {
    const regions = this.getRegions();
    if (!regions.length) return;

    const ctx = this.ensureAudioCtx();
    this.lastBpm = this.getBpm();
    const secPerBeat = 60 / this.lastBpm;

    this.playing = true;
    this.startTime = ctx.currentTime - fromBeat * secPerBeat;
    this.currentIndex = -1;
    this.nextTickBeat = Math.ceil(fromBeat - 1e-6);

    if (this.rafId) cancelAnimationFrame(this.rafId);
    this._loop();
  }

  stop() {
    this.playing = false;
    if (this.rafId) cancelAnimationFrame(this.rafId);
    this.rafId = null;
    this.currentIndex = -1;
  }

  _loop() {
    if (!this.playing) return;
    const ctx = this.audioCtx;
    const bpm = this.getBpm();

    if (bpm !== this.lastBpm) {
      const prevSecPerBeat = 60 / (this.lastBpm || bpm);
      const continuousBeat = (ctx.currentTime - this.startTime) / prevSecPerBeat;
      const newSecPerBeat = 60 / bpm;
      this.startTime = ctx.currentTime - continuousBeat * newSecPerBeat;
      this.nextTickBeat = Math.ceil(continuousBeat - 1e-6);
      this.lastBpm = bpm;
    }

    const secPerBeat = 60 / bpm;
    const regions = this.getRegions();
    const totalBeats = regions.reduce((sum, r) => sum + r.beats, 0);

    if (totalBeats <= 0) {
      this.stop();
      this.onStop?.();
      return;
    }

    const elapsed = ctx.currentTime - this.startTime;
    const absoluteBeat = elapsed / secPerBeat;

    if (absoluteBeat >= totalBeats && !this.getLoop()) {
      this.stop();
      this.onStop?.();
      return;
    }

    const beatPos = ((absoluteBeat % totalBeats) + totalBeats) % totalBeats;

    let acc = 0;
    let idx = 0;
    for (; idx < regions.length; idx++) {
      acc += regions[idx].beats;
      if (beatPos < acc) break;
    }
    idx = Math.min(idx, regions.length - 1);

    if (idx !== this.currentIndex) {
      this.currentIndex = idx;
      this.onRegionChange?.(idx, regions[idx]);
    }

    if (this.getMetronomeOn()) {
      while (this.startTime + this.nextTickBeat * secPerBeat < ctx.currentTime + this.scheduleAheadTime) {
        const tickTime = this.startTime + this.nextTickBeat * secPerBeat;
        if (tickTime >= ctx.currentTime - 0.02) {
          this._playClick(tickTime);
        }
        this.nextTickBeat += 1;
      }
    }

    this.rafId = requestAnimationFrame(this._loop);
  }

  _playClick(time) {
    const ctx = this.audioCtx;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.frequency.value = 1000;
    gain.gain.setValueAtTime(0.0001, time);
    gain.gain.exponentialRampToValueAtTime(0.5, time + 0.001);
    gain.gain.exponentialRampToValueAtTime(0.0001, time + 0.05);
    osc.connect(gain).connect(ctx.destination);
    osc.start(time);
    osc.stop(time + 0.06);
  }
}
