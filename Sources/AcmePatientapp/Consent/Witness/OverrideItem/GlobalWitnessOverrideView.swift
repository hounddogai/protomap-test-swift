import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global witness override.
    final class GlobalWitnessOverrideView {
        var code: String
        var labelText: String
        var archived: String
        var minimum: String
        var sequence: String
        var segmentText: String
        var attempts: String
        var encounterID: String
        var checksum: String
        var pinned: String
        var statusLabel: String

        init(code: String, labelText: String, archived: String, minimum: String, sequence: String, segmentText: String, attempts: String, encounterID: String, checksum: String, pinned: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archived = archived
            self.minimum = minimum
            self.sequence = sequence
            self.segmentText = segmentText
            self.attempts = attempts
            self.encounterID = encounterID
            self.checksum = checksum
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalWitnessOverrideView(_ item: GlobalWitnessOverride) -> GlobalWitnessOverrideView {
        return GlobalWitnessOverrideView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            archived: "\(item.archived)",
            minimum: String(format: "%.2f", item.minimum),
            sequence: String(item.sequence),
            segmentText: item.segment,
            attempts: String(item.attempts),
            encounterID: item.encounterID,
            checksum: item.checksum,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalWitnessOverrideViews(_ items: [GlobalWitnessOverride]) -> [GlobalWitnessOverrideView] {
        var views: [GlobalWitnessOverrideView] = []
        for item in items {
            views.append(toGlobalWitnessOverrideView(item))
        }
        return views
    }

    static func sumGlobalWitnessOverrideView(_ view: GlobalWitnessOverrideView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMinimum + Double(parsedSequence) + Double(parsedAttempts)
    }
}
