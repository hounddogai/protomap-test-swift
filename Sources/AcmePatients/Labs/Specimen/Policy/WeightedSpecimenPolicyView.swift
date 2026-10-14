import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted specimen policy.
    final class WeightedSpecimenPolicyView {
        var code: String
        var label: String
        var pinned: String
        var createdAt: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, pinned: String, createdAt: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.createdAt = createdAt
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSpecimenPolicyView(_ item: WeightedSpecimenPolicy) -> WeightedSpecimenPolicyView {
        return WeightedSpecimenPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            pinned: "\(item.pinned)",
            createdAt: String(item.createdAt),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSpecimenPolicyViews(_ items: [WeightedSpecimenPolicy]) -> [WeightedSpecimenPolicyView] {
        var views: [WeightedSpecimenPolicyView] = []
        for item in items {
            views.append(toWeightedSpecimenPolicyView(item))
        }
        return views
    }

    static func sumWeightedSpecimenPolicyView(_ view: WeightedSpecimenPolicyView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedSequence)
    }
}
