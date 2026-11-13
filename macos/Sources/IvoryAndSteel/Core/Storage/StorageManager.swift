import Foundation

// MARK: - Persistent Storage Models

public struct PracticeSessionRecord: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var durationSeconds: Int
    public var title: String
    public var completedChecklistItems: [String]
    public var bpm: Double?
    public var notes: String?
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        durationSeconds: Int,
        title: String,
        completedChecklistItems: [String] = [],
        bpm: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.title = title
        self.completedChecklistItems = completedChecklistItems
        self.bpm = bpm
        self.notes = notes
    }
}

public struct QuizResultRecord: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var score: Int
    public var totalQuestions: Int
    public var levelName: String
    public var category: String?
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        score: Int,
        totalQuestions: Int,
        levelName: String,
        category: String? = nil
    ) {
        self.id = id
        self.date = date
        self.score = score
        self.totalQuestions = totalQuestions
        self.levelName = levelName
        self.category = category
    }
}

public struct AppSettingsRecord: Codable, Sendable, Equatable {
    public var audioBufferSize: Int = 256
    public var midiDeviceName: String = "All CoreMIDI Inputs"
    public var soundfontModel: String = "Steinway Concert Grand (Acoustic DSP)"
    public var theme: String = "Concert Grand Dark"
    public var metronomeSound: String = "Steinway Woodblock"
    public var practiceGoalMinutesPerDay: Int = 30
    public var autoCheckForUpdates: Bool = true
    public var includePrereleases: Bool = false
    public var skippedReleaseTag: String? = nil
    public var lastUpdateCheckDate: Date? = nil
    
    public init(
        audioBufferSize: Int = 256,
        midiDeviceName: String = "All CoreMIDI Inputs",
        soundfontModel: String = "Steinway Concert Grand (Acoustic DSP)",
        theme: String = "Concert Grand Dark",
        metronomeSound: String = "Steinway Woodblock",
        practiceGoalMinutesPerDay: Int = 30,
        autoCheckForUpdates: Bool = true,
        includePrereleases: Bool = false,
        skippedReleaseTag: String? = nil,
        lastUpdateCheckDate: Date? = nil
    ) {
        self.audioBufferSize = audioBufferSize
        self.midiDeviceName = midiDeviceName
        self.soundfontModel = soundfontModel
        self.theme = theme
        self.metronomeSound = metronomeSound
        self.practiceGoalMinutesPerDay = practiceGoalMinutesPerDay
        self.autoCheckForUpdates = autoCheckForUpdates
        self.includePrereleases = includePrereleases
        self.skippedReleaseTag = skippedReleaseTag
        self.lastUpdateCheckDate = lastUpdateCheckDate
    }
    
    enum CodingKeys: String, CodingKey {
        case audioBufferSize
        case midiDeviceName
        case soundfontModel
        case theme
        case metronomeSound
        case practiceGoalMinutesPerDay
        case autoCheckForUpdates
        case includePrereleases
        case skippedReleaseTag
        case lastUpdateCheckDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.audioBufferSize = try container.decodeIfPresent(Int.self, forKey: .audioBufferSize) ?? 256
        self.midiDeviceName = try container.decodeIfPresent(String.self, forKey: .midiDeviceName) ?? "All CoreMIDI Inputs"
        self.soundfontModel = try container.decodeIfPresent(String.self, forKey: .soundfontModel) ?? "Steinway Concert Grand (Acoustic DSP)"
        self.theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? "Concert Grand Dark"
        self.metronomeSound = try container.decodeIfPresent(String.self, forKey: .metronomeSound) ?? "Steinway Woodblock"
        self.practiceGoalMinutesPerDay = try container.decodeIfPresent(Int.self, forKey: .practiceGoalMinutesPerDay) ?? 30
        self.autoCheckForUpdates = try container.decodeIfPresent(Bool.self, forKey: .autoCheckForUpdates) ?? true
        self.includePrereleases = try container.decodeIfPresent(Bool.self, forKey: .includePrereleases) ?? false
        self.skippedReleaseTag = try container.decodeIfPresent(String.self, forKey: .skippedReleaseTag)
        self.lastUpdateCheckDate = try container.decodeIfPresent(Date.self, forKey: .lastUpdateCheckDate)
    }
}

public struct StorageData: Codable, Sendable, Equatable {
    public var practiceSessions: [PracticeSessionRecord] = []
    public var quizResults: [QuizResultRecord] = []
    public var bookmarkedTipIds: [String] = []
    public var settings: AppSettingsRecord = AppSettingsRecord()
    
    public init() {}
    
    enum CodingKeys: String, CodingKey {
        case practiceSessions
        case quizResults
        case bookmarkedTipIds
        case settings
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.practiceSessions = try container.decodeIfPresent([PracticeSessionRecord].self, forKey: .practiceSessions) ?? []
        self.quizResults = try container.decodeIfPresent([QuizResultRecord].self, forKey: .quizResults) ?? []
        self.bookmarkedTipIds = try container.decodeIfPresent([String].self, forKey: .bookmarkedTipIds) ?? []
        self.settings = try container.decodeIfPresent(AppSettingsRecord.self, forKey: .settings) ?? AppSettingsRecord()
    }
}

/// Thread-safe storage manager that persists practice routines, quiz scores, bookmarks,
/// and user preferences to `~/Library/Application Support/IvoryAndSteel/storage.json`.
public final class StorageManager: @unchecked Sendable {
    public static let shared = StorageManager()
    
    private let fileURL: URL
    private let lock = NSLock()
    private var data: StorageData
    
    public init(customFileURL: URL? = nil) {
        if let custom = customFileURL {
            self.fileURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("IvoryAndSteel", isDirectory: true)
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
            self.fileURL = appDir.appendingPathComponent("storage.json")
        }
        
        self.data = StorageData()
        self.load()
    }
    
    public func load() {
        lock.lock()
        defer { lock.unlock() }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let bytes = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.data = try decoder.decode(StorageData.self, from: bytes)
        } catch {
            print("StorageManager failed to decode storage.json: \(error)")
        }
    }
    
    public func save() {
        lock.lock()
        defer { lock.unlock() }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let bytes = try encoder.encode(self.data)
            try bytes.write(to: fileURL, options: .atomic)
        } catch {
            print("StorageManager failed to write storage.json: \(error)")
        }
    }
    
    // MARK: - Accessors
    
    public var practiceSessions: [PracticeSessionRecord] {
        lock.lock()
        defer { lock.unlock() }
        return data.practiceSessions
    }
    
    public func addPracticeSession(_ session: PracticeSessionRecord) {
        lock.lock()
        data.practiceSessions.insert(session, at: 0)
        lock.unlock()
        save()
    }
    
    public func clearPracticeSessions() {
        lock.lock()
        data.practiceSessions.removeAll()
        lock.unlock()
        save()
    }
    
    public var quizResults: [QuizResultRecord] {
        lock.lock()
        defer { lock.unlock() }
        return data.quizResults
    }
    
    public func addQuizResult(_ result: QuizResultRecord) {
        lock.lock()
        data.quizResults.insert(result, at: 0)
        lock.unlock()
        save()
    }
    
    public func clearQuizResults() {
        lock.lock()
        data.quizResults.removeAll()
        lock.unlock()
        save()
    }
    
    public var bookmarkedTipIds: [String] {
        lock.lock()
        defer { lock.unlock() }
        return data.bookmarkedTipIds
    }
    
    public func toggleBookmark(tipId: String) {
        lock.lock()
        if let idx = data.bookmarkedTipIds.firstIndex(of: tipId) {
            data.bookmarkedTipIds.remove(at: idx)
        } else {
            data.bookmarkedTipIds.append(tipId)
        }
        lock.unlock()
        save()
    }
    
    public func isBookmarked(tipId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return data.bookmarkedTipIds.contains(tipId)
    }
    
    public var settings: AppSettingsRecord {
        lock.lock()
        defer { lock.unlock() }
        return data.settings
    }
    
    public func updateSettings(_ update: (inout AppSettingsRecord) -> Void) {
        lock.lock()
        update(&data.settings)
        lock.unlock()
        save()
    }
}

