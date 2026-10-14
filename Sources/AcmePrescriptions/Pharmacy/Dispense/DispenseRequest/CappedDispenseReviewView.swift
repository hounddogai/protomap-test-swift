import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped dispense review.
    final class CappedDispenseReviewView {
        var code: String
        var labelText: String
        var diagnosisCodeText: String
        var nameText: String
        var checksum: String
        var notes: String
        var channelText: String
        var priorityText: String
        var statusLabel: String

        init(code: String, labelText: String, diagnosisCodeText: String, nameText: String, checksum: String, notes: String, channelText: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.diagnosisCodeText = diagnosisCodeText
            self.nameText = nameText
            self.checksum = checksum
            self.notes = notes
            self.channelText = channelText
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDispenseReviewView(_ item: CappedDispenseReview) -> CappedDispenseReviewView {
        return CappedDispenseReviewView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            nameText: item.name,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            notes: item.notes,
            channelText: item.channel,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDispenseReviewViews(_ items: [CappedDispenseReview]) -> [CappedDispenseReviewView] {
        var views: [CappedDispenseReviewView] = []
        for item in items {
            views.append(toCappedDispenseReviewView(item))
        }
        return views
    }

    static func sumCappedDispenseReviewView(_ view: CappedDispenseReviewView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
