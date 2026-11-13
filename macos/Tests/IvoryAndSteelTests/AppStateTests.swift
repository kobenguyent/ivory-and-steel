import XCTest
@testable import IvoryAndSteel

final class AppStateTests: XCTestCase {
    
    var state: AppState!
    
    override func setUp() {
        super.setUp()
        state = AppState()
    }
    
    override func tearDown() {
        state = nil
        super.tearDown()
    }
    
    // MARK: - Tab Selection Tests
    
    func testInitialTabIsTheoryExplorer() {
        XCTAssertEqual(state.selectedTab, .theoryExplorer)
    }
    
    func testSelectTabDirectly() {
        state.selectTab(.virtualPiano)
        XCTAssertEqual(state.selectedTab, .virtualPiano)
        
        state.selectTab(.guitarFretboard)
        XCTAssertEqual(state.selectedTab, .guitarFretboard)
        
        state.selectTab(.metronome)
        XCTAssertEqual(state.selectedTab, .metronome)
        
        state.selectTab(.practiceRoutine)
        XCTAssertEqual(state.selectedTab, .practiceRoutine)
        
        state.selectTab(.masterclassHub)
        XCTAssertEqual(state.selectedTab, .masterclassHub)
        
        state.selectTab(.musicianQuiz)
        XCTAssertEqual(state.selectedTab, .musicianQuiz)
    }
    
    func testSelectTabByIndex() {
        // Index 0 -> Theory Explorer
        state.selectTabByIndex(0)
        XCTAssertEqual(state.selectedTab, .theoryExplorer)
        
        // Index 1 -> Virtual Piano
        state.selectTabByIndex(1)
        XCTAssertEqual(state.selectedTab, .virtualPiano)
        
        // Index 2 -> Guitar Fretboard
        state.selectTabByIndex(2)
        XCTAssertEqual(state.selectedTab, .guitarFretboard)
        
        // Index 3 -> Metronome
        state.selectTabByIndex(3)
        XCTAssertEqual(state.selectedTab, .metronome)
        
        // Index 4 -> Practice Routine
        state.selectTabByIndex(4)
        XCTAssertEqual(state.selectedTab, .practiceRoutine)
        
        // Index 5 -> Masterclass Hub
        state.selectTabByIndex(5)
        XCTAssertEqual(state.selectedTab, .masterclassHub)
        
        // Index 6 -> Musician Quiz
        state.selectTabByIndex(6)
        XCTAssertEqual(state.selectedTab, .musicianQuiz)
        
        // Out of bounds indices should be safely ignored
        state.selectTabByIndex(99)
        XCTAssertEqual(state.selectedTab, .musicianQuiz)
        
        state.selectTabByIndex(-1)
        XCTAssertEqual(state.selectedTab, .musicianQuiz)
    }
    
    // MARK: - Root Key & Flat Preference Tests
    
    func testDefaultRootKeyIsC() {
        XCTAssertEqual(state.rootKey, "C")
        XCTAssertFalse(state.preferFlat)
    }
    
    func testSetRootKeyUpdatesPreferFlatAutomatically() {
        // Flat keys
        state.setRootKey("F")
        XCTAssertTrue(state.preferFlat, "Key of F should automatically prefer flats")
        
        state.setRootKey("Bb")
        XCTAssertTrue(state.preferFlat, "Key of Bb should automatically prefer flats")
        
        state.setRootKey("Eb")
        XCTAssertTrue(state.preferFlat, "Key of Eb should automatically prefer flats")
        
        state.setRootKey("Ab")
        XCTAssertTrue(state.preferFlat, "Key of Ab should automatically prefer flats")
        
        // Sharp / Natural keys
        state.setRootKey("G")
        XCTAssertFalse(state.preferFlat, "Key of G should not prefer flats")
        
        state.setRootKey("D")
        XCTAssertFalse(state.preferFlat, "Key of D should not prefer flats")
        
        state.setRootKey("A")
        XCTAssertFalse(state.preferFlat, "Key of A should not prefer flats")
        
        state.setRootKey("E")
        XCTAssertFalse(state.preferFlat, "Key of E should not prefer flats")
    }
    
    func testTogglePreferFlatManually() {
        state.setRootKey("C")
        XCTAssertFalse(state.preferFlat)
        
        state.togglePreferFlat()
        XCTAssertTrue(state.preferFlat)
        
        state.togglePreferFlat()
        XCTAssertFalse(state.preferFlat)
    }
    
    // MARK: - Mute & Metronome Controls
    
    func testToggleMute() {
        XCTAssertFalse(state.isMuted)
        
        state.toggleMute()
        XCTAssertTrue(state.isMuted)
        
        state.toggleMute()
        XCTAssertFalse(state.isMuted)
    }
    
    func testToggleMetronome() {
        XCTAssertFalse(state.isMetronomePlaying)
        
        state.toggleMetronome()
        XCTAssertTrue(state.isMetronomePlaying)
        
        state.toggleMetronome()
        XCTAssertFalse(state.isMetronomePlaying)
    }
    
    func testSetBPMClamping() {
        state.setBPM(140.0)
        XCTAssertEqual(state.metronomeBPM, 140.0)
        
        // Clamp lower bound (30 BPM)
        state.setBPM(10.0)
        XCTAssertEqual(state.metronomeBPM, 30.0)
        
        // Clamp upper bound (300 BPM)
        state.setBPM(500.0)
        XCTAssertEqual(state.metronomeBPM, 300.0)
    }
    
    // MARK: - Scale & Chord Selections
    
    func testSetScaleAndChordId() {
        state.setScaleId("dorian")
        XCTAssertEqual(state.selectedScaleId, "dorian")
        
        state.setChordId("maj7")
        XCTAssertEqual(state.selectedChordId, "maj7")
    }
    
    // MARK: - MIDI Event Handling
    
    func testMIDINoteOnOff() {
        let expectation = XCTestExpectation(description: "MIDI Note insertion")
        state.handleMIDINoteOn(midi: 60, velocity: 0.8)
        
        DispatchQueue.main.async {
            XCTAssertTrue(self.state.activeMidiNotes.contains(60))
            self.state.handleMIDINoteOff(midi: 60)
            DispatchQueue.main.async {
                XCTAssertFalse(self.state.activeMidiNotes.contains(60))
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - StorageManager Tests
    
    func testStorageManagerSaveAndRetrieve() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_storage_\(UUID().uuidString).json")
        let storage = StorageManager(customFileURL: tempURL)
        
        // Test practice session
        let session = PracticeSessionRecord(
            durationSeconds: 1800,
            title: "Test Routine",
            completedChecklistItems: ["Step 1", "Step 2"],
            bpm: 120.0
        )
        storage.addPracticeSession(session)
        XCTAssertEqual(storage.practiceSessions.count, 1)
        XCTAssertEqual(storage.practiceSessions.first?.title, "Test Routine")
        
        // Test quiz result
        let quiz = QuizResultRecord(
            score: 9,
            totalQuestions: 10,
            levelName: "Virtuoso Maestro",
            category: "piano"
        )
        storage.addQuizResult(quiz)
        XCTAssertEqual(storage.quizResults.count, 1)
        XCTAssertEqual(storage.quizResults.first?.score, 9)
        
        // Test bookmarks
        storage.toggleBookmark(tipId: "tip-01")
        XCTAssertTrue(storage.isBookmarked(tipId: "tip-01"))
        storage.toggleBookmark(tipId: "tip-01")
        XCTAssertFalse(storage.isBookmarked(tipId: "tip-01"))
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testStorageManagerPracticeTasksPersistenceAndLegacyBackwardCompatibility() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_tasks_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        // Simulate legacy storage.json written before practiceTasks existed
        let legacyJSON = """
        {
          "bookmarkedTipIds": ["tip-01"],
          "practiceSessions": [],
          "quizResults": []
        }
        """
        try legacyJSON.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let storage = StorageManager(customFileURL: tempURL)
        XCTAssertTrue(storage.isBookmarked(tipId: "tip-01"))
        XCTAssertEqual(storage.practiceTasks.count, PracticeChecklistTask.defaultProtocol.count)
        
        // Mutate and persist custom tasks
        let customTask = PracticeChecklistTask(
            id: "custom-1",
            title: "Chopin Etude Op. 10 No. 1 Arpeggios",
            details: "Keep thumb release light and relaxed.",
            estimatedMinutes: 10,
            targetBPM: 72,
            isCompleted: true
        )
        storage.savePracticeTasks([customTask])
        
        let reloaded = StorageManager(customFileURL: tempURL)
        XCTAssertEqual(reloaded.practiceTasks.count, 1)
        XCTAssertEqual(reloaded.practiceTasks.first?.title, "Chopin Etude Op. 10 No. 1 Arpeggios")
        XCTAssertEqual(reloaded.practiceTasks.first?.targetBPM, 72)
        XCTAssertEqual(reloaded.practiceTasks.first?.isCompleted, true)
        
        let restored = reloaded.resetPracticeTasksToDefault()
        XCTAssertEqual(restored.count, PracticeChecklistTask.defaultProtocol.count)
    }

    func testPlayQuizCueAndStopCancellation() {
        let cue = QuizAudioCue(
            style: .melodic,
            notes: ["C4", "Ab4"],
            referenceRootNote: "C4",
            stepDuration: 0.4,
            isGuitar: false
        )

        state.playQuizCue(cue)
        XCTAssertEqual(state.activeVoicingNotes, ["C4", "Ab4"])

        state.stopQuizPlayback()
        XCTAssertTrue(state.activeVoicingNotes.isEmpty)

        // Muted state must suppress new playback and leave voicing notes clean
        state.toggleMute()
        XCTAssertTrue(state.isMuted)
        state.playQuizCue(cue)
        XCTAssertTrue(state.activeVoicingNotes.isEmpty)
    }

    func testStorageManagerAppSettingsPersistenceAndLegacyBackwardCompatibility() throws {
        let legacySettingsJSON = """
        {
          "audioBufferSize": 512,
          "midiDeviceName": "Nord Stage 4",
          "soundfontModel": "Hamburg Steinway D",
          "theme": "ebony",
          "metronomeSound": "woodblock",
          "practiceGoalMinutesPerDay": 45
        }
        """
        let decodedLegacy = try JSONDecoder().decode(
            AppSettingsRecord.self,
            from: Data(legacySettingsJSON.utf8)
        )
        XCTAssertEqual(decodedLegacy.audioBufferSize, 512)
        XCTAssertEqual(decodedLegacy.midiDeviceName, "Nord Stage 4")
        XCTAssertEqual(decodedLegacy.soundfontModel, "Hamburg Steinway D")
        XCTAssertEqual(decodedLegacy.guitarModel, "Boutique Luthier Steel String")
        XCTAssertEqual(decodedLegacy.practiceGoalMinutesPerDay, 45)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ivory-steel-settings-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let storage = StorageManager(customFileURL: tempURL)
        XCTAssertEqual(storage.storageFileURL, tempURL)
        XCTAssertEqual(storage.settings.guitarModel, "Boutique Luthier Steel String")

        storage.updateSettings { settings in
            settings.audioBufferSize = 128
            settings.soundfontModel = "Bösendorfer 290 Imperial"
            settings.guitarModel = "Concert Classical Nylon"
        }

        let reloaded = StorageManager(customFileURL: tempURL)
        XCTAssertEqual(reloaded.storageFileURL, tempURL)
        XCTAssertEqual(reloaded.settings.audioBufferSize, 128)
        XCTAssertEqual(reloaded.settings.soundfontModel, "Bösendorfer 290 Imperial")
        XCTAssertEqual(reloaded.settings.guitarModel, "Concert Classical Nylon")
    }

    // MARK: - Cross-Page Navigation Handoffs

    func testOpenInPianoAndGuitarStudiosSyncsStateAndTab() {
        state.openInPianoStudio(root: "Eb", voicingNotes: ["Eb4", "G4", "Bb4", "D5"])
        XCTAssertEqual(state.selectedTab, .virtualPiano)
        XCTAssertEqual(state.activeInstrument, "piano")
        XCTAssertEqual(state.rootKey, "Eb")
        XCTAssertTrue(state.preferFlat)
        XCTAssertEqual(state.activeVoicingNotes, ["Eb4", "G4", "Bb4", "D5"])
        XCTAssertFalse(state.pianoGuideEnabled)

        state.openInGuitarStudio(root: "A", scaleId: "dorian")
        XCTAssertEqual(state.selectedTab, .guitarFretboard)
        XCTAssertEqual(state.activeInstrument, "guitar")
        XCTAssertEqual(state.rootKey, "A")
        XCTAssertEqual(state.selectedScaleId, "dorian")
        XCTAssertEqual(state.guitarGuideScaleId, "dorian")
        XCTAssertTrue(state.guitarGuideEnabled)
    }

    func testMasterclassAndMetronomeAndPracticeNavigationHandoffs() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ivory-steel-handoff-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let storage = StorageManager(customFileURL: tempURL)

        state.openMetronome(atBPM: 96)
        XCTAssertEqual(state.selectedTab, .metronome)
        XCTAssertEqual(state.metronomeBPM, 96)

        state.openMasterclassTopic(id: "tip-04")
        XCTAssertEqual(state.selectedTab, .masterclassHub)
        XCTAssertEqual(state.masterclassSelectedTipId, "tip-04")

        state.addTaskToPracticeRoutine(
            title: "C Major Hands Separate Arpeggios",
            details: "Keep wrist loose across thumb pass.",
            estimatedMinutes: 8,
            targetBPM: 72,
            navigate: true,
            storage: storage
        )
        XCTAssertEqual(state.selectedTab, .practiceRoutine)
        XCTAssertTrue(storage.practiceTasks.contains { $0.title == "C Major Hands Separate Arpeggios" && $0.targetBPM == 72 })
    }
}

