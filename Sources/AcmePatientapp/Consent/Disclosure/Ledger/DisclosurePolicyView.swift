import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure policy.
    final class DisclosurePolicyView {
        var code: String
        var name: String
        var procedureCodeText: String
        var segmentText: String
        var capacityText: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, segmentText: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.segmentText = segmentText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosurePolicyView(_ item: DisclosurePolicy) -> DisclosurePolicyView {
        return DisclosurePolicyView(
            code: item.code,
            name: item.name,
            procedureCodeText: item.procedureCode,
            segmentText: item.segment,
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosurePolicyViews(_ items: [DisclosurePolicy]) -> [DisclosurePolicyView] {
        var views: [DisclosurePolicyView] = []
        for item in items {
            views.append(toDisclosurePolicyView(item))
        }
        return views
    }

    static func sumDisclosurePolicyView(_ view: DisclosurePolicyView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
