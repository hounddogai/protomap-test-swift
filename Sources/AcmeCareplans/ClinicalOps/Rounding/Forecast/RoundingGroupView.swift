import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding group.
    final class RoundingGroupView {
        var code: String
        var nameText: String
        var diagnosisCodeText: String
        var notes: String
        var allergy: String
        var retries: String
        var statusLabel: String

        init(code: String, nameText: String, diagnosisCodeText: String, notes: String, allergy: String, retries: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.diagnosisCodeText = diagnosisCodeText
            self.notes = notes
            self.allergy = allergy
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingGroupView(_ item: RoundingGroup) -> RoundingGroupView {
        return RoundingGroupView(
            code: item.code,
            nameText: item.name,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            allergy: item.allergy,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingGroupViews(_ items: [RoundingGroup]) -> [RoundingGroupView] {
        var views: [RoundingGroupView] = []
        for item in items {
            views.append(toRoundingGroupView(item))
        }
        return views
    }

    static func sumRoundingGroupView(_ view: RoundingGroupView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
