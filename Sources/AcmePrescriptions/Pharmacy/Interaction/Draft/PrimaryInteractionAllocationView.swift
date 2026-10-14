import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary interaction allocation.
    final class PrimaryInteractionAllocationView {
        var code: String
        var labelText: String
        var startsAtText: String
        var weight: String
        var checksum: String
        var statusLabel: String

        init(code: String, labelText: String, startsAtText: String, weight: String, checksum: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.startsAtText = startsAtText
            self.weight = weight
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryInteractionAllocationView(_ item: PrimaryInteractionAllocation) -> PrimaryInteractionAllocationView {
        return PrimaryInteractionAllocationView(
            code: item.code,
            labelText: item.label,
            startsAtText: String(item.startsAt),
            weight: String(format: "%.2f", item.weight),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryInteractionAllocationViews(_ items: [PrimaryInteractionAllocation]) -> [PrimaryInteractionAllocationView] {
        var views: [PrimaryInteractionAllocationView] = []
        for item in items {
            views.append(toPrimaryInteractionAllocationView(item))
        }
        return views
    }

    static func sumPrimaryInteractionAllocationView(_ view: PrimaryInteractionAllocationView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedStartsAt) + parsedWeight
    }
}
