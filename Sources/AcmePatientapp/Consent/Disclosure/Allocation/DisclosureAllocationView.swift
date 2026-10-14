import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure allocation.
    final class DisclosureAllocationView {
        var code: String
        var label: String
        var version: String
        var segmentText: String
        var procedureCode: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, version: String, segmentText: String, procedureCode: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.version = version
            self.segmentText = segmentText
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureAllocationView(_ item: DisclosureAllocation) -> DisclosureAllocationView {
        return DisclosureAllocationView(
            code: item.code,
            label: item.label,
            version: String(item.version),
            segmentText: item.segment,
            procedureCode: item.procedureCode,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureAllocationViews(_ items: [DisclosureAllocation]) -> [DisclosureAllocationView] {
        var views: [DisclosureAllocationView] = []
        for item in items {
            views.append(toDisclosureAllocationView(item))
        }
        return views
    }

    static func sumDisclosureAllocationView(_ view: DisclosureAllocationView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedVersion) + Double(parsedQuantity)
    }
}
