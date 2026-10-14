import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study snapshot.
    final class StudySnapshotView {
        var code: String
        var nameText: String
        var endsAtText: String
        var procedureCodeText: String
        var sourceText: String
        var createdAtText: String
        var checksum: String
        var title: String
        var attemptsText: String
        var batchSize: String
        var rate: String
        var statusLabel: String

        init(code: String, nameText: String, endsAtText: String, procedureCodeText: String, sourceText: String, createdAtText: String, checksum: String, title: String, attemptsText: String, batchSize: String, rate: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.endsAtText = endsAtText
            self.procedureCodeText = procedureCodeText
            self.sourceText = sourceText
            self.createdAtText = createdAtText
            self.checksum = checksum
            self.title = title
            self.attemptsText = attemptsText
            self.batchSize = batchSize
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toStudySnapshotView(_ item: StudySnapshot) -> StudySnapshotView {
        return StudySnapshotView(
            code: item.code,
            nameText: item.name,
            endsAtText: String(item.endsAt),
            procedureCodeText: item.procedureCode,
            sourceText: item.source,
            createdAtText: String(item.createdAt),
            checksum: item.checksum,
            title: item.title,
            attemptsText: String(item.attempts),
            batchSize: String(item.batchSize),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudySnapshotViews(_ items: [StudySnapshot]) -> [StudySnapshotView] {
        var views: [StudySnapshotView] = []
        for item in items {
            views.append(toStudySnapshotView(item))
        }
        return views
    }

    static func sumStudySnapshotView(_ view: StudySnapshotView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCreatedAt) + Double(parsedAttempts)
    }
}
