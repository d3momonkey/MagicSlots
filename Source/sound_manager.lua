local snd = playdate.sound

SoundManager = {}

local spinTickSynth = nil
local reelStopSynth = nil
local winSynth = nil
local winSequence = nil
local startSynth = nil
local tensionSynth = nil

local loseSynth = nil

function SoundManager.init()
    -- 1. Spin Tick (Mechanical Click)
    spinTickSynth = snd.synth.new(snd.kWaveNoise)
    local tickEnv = snd.envelope.new(0, 0, 0, 0.05) -- Instant attack, fast decay
    -- Correct method: setAttack/Decay/Sustain/Release individually OR assign to modulation
    -- For Synth, we usually assume ADSR is built-in or use setEnvelope for amplitude if available.
    -- Checking SDK docs: playdate.sound.synth uses :setADSR(attack, decay, sustain, release)
    spinTickSynth:setADSR(0, 0.05, 0, 0)
    spinTickSynth:setVolume(0.3)

    -- 2. Reel Stop (Heavy Thud)
    reelStopSynth = snd.synth.new(snd.kWaveSquare)
    reelStopSynth:setADSR(0, 0.1, 0, 0)
    reelStopSynth:setVolume(0.4)
    
    -- 3. Spin Start (Rising Tone)
    startSynth = snd.synth.new(snd.kWaveTriangle)
    startSynth:setADSR(0.1, 0.2, 0, 0)
    startSynth:setVolume(0.4)

    -- 4. Win Jingle (Bell-like Sequence)
    winSynth = snd.synth.new(snd.kWaveSine)
    winSynth:setADSR(0.01, 0.4, 0, 0) -- Bell shape: fast attack, long decay
    winSynth:setVolume(0.5)
    
    winSequence = snd.sequence.new()
    -- Create a track for the synth
    local track = winSequence:addTrack()
    track:setInstrument(winSynth)
    -- Add notes: C5, E5, G5, C6
    -- step, note, velocity, length
    track:addNote(1, "C5", 1)
    track:addNote(3, "E5", 1)
    track:addNote(5, "G5", 1)
    track:addNote(7, "C6", 1, 4) -- Hold last note
    
    winSequence:setTempo(10) -- Fast tempo
    winSequence:setLoops(1)

    -- 5. Lose (Low Beep)
    loseSynth = snd.synth.new(snd.kWaveSawtooth)
    loseSynth:setADSR(0, 0.2, 0, 0)
    loseSynth:setVolume(0.3)
    
    -- 6. Tension (Rising Pitch)
    -- Switch back to Sine wave for softer tone
    tensionSynth = snd.synth.new(snd.kWaveSine)
    -- Simple ADSR
    tensionSynth:setADSR(0, 0, 1, 0) 
    -- Low Volume
    tensionSynth:setVolume(0.2)
    
    -- Frequency Modulator (LFO/Envelope) to bend pitch up
    -- We use an envelope to ramp value from 0 to 1 over e.g. 2 seconds
    local pitchEnv = snd.envelope.new(0, 0, 0, 0) -- Params don't matter as much for custom signal, we will re-trigger
    -- Actually, for pitch bend, we usually use an LFO or a signal.
    -- Let's use a simple LFO (Sawtooth Up) or Envelope attached to frequency modulator.
    -- Better: Use a Signal (Envelope) to modulate frequency.
    local bendSignal = snd.lfo.new(snd.kLFOSawtoothUp)
    -- Slow it down: 0.2Hz = 5 seconds to complete one rise
    bendSignal:setRate(0.2) 
    bendSignal:setDepth(12) -- 12 semitones = 1 octave
    -- By default LFO cycles. We want it to just go up.
    -- Playdate LFOs cycle. 
    -- Alternative: Use setFrequencyModulator with an Envelope.
    -- Create an envelope that goes from 0 to 1
    local bendEnv = snd.envelope.new(2.0, 0, 1, 0) -- Attack 2.0s (Rise time)
    -- Envelope output is 0..1. We need to scale this to frequency or pitch.
    -- setFrequencyModulator takes a signal.
    -- But synth:setFrequencyModulator adds to the base frequency.
    
    -- Correct method is setFrequencyMod, not setFrequencyModulator for Synth (it seems setFrequencyModulator is for Instrument/Channel or similar, or simply misremembered API)
    -- Checking docs: synth:setFrequencyMod(signal)
    tensionSynth:setFrequencyMod(bendSignal)
end

function SoundManager.play(soundName)
    if soundName == "tick" then
        if spinTickSynth then spinTickSynth:playNote(100, 0.05) end -- Frequency doesn't matter much for noise
    elseif soundName == "stop" then
        if reelStopSynth then reelStopSynth:playNote("C2", 0.1) end
    elseif soundName == "start" then
        -- Play a quick rising slide manually or just a note
        if startSynth then 
            startSynth:playNote("C4", 0.2) 
            -- Optional: Pitch bend could go here
        end
    elseif soundName == "win" then
        if winSequence then 
            winSequence:play() 
        end
    elseif soundName == "lose" then
        if loseSynth then
            loseSynth:playNote("C2", 0.2)
        end
    elseif soundName == "tension" then
        if tensionSynth then
            print("Playing Tension Sound") -- Debug Print
            tensionSynth:stop() 
            tensionSynth:playNote("C3") -- Use C3 for lower pitch
        end
    elseif soundName == "tension_stop" then
        if tensionSynth then
            tensionSynth:stop()
        end
    end
end

return SoundManager
