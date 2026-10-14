import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary substitution allocation.
    final class PrimarySubstitutionAllocationView {
        var code: String
        var name: String
        var limit: String
        var visible: String
        var wardText: String
        var ownerID: String
        var quantity: String
        var checksum: String
        var unit: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, name: String, limit: String, visible: String, wardText: String, ownerID: String, quantity: String, checksum: String, unit: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.visible = visible
            self.wardText = wardText
            self.ownerID = ownerID
            self.quantity = quantity
            self.checksum = checksum
            self.unit = unit
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySubstitutionAllocationView(_ item: PrimarySubstitutionAllocation) -> PrimarySubstitutionAllocationView {
        return PrimarySubstitutionAllocationView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            limit: String(item.limit),
            visible: "\(item.visible)",
            wardText: item.ward,
            ownerID: item.ownerID,
            quantity: String(item.quantity),
            checksum: item.checksum,
            unit: item.unit,
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySubstitutionAllocationViews(_ items: [PrimarySubstitutionAllocation]) -> [PrimarySubstitutionAllocationView] {
        var views: [PrimarySubstitutionAllocationView] = []
        for item in items {
            views.append(toPrimarySubstitutionAllocationView(item))
        }
        return views
    }

    static func sumPrimarySubstitutionAllocationView(_ view: PrimarySubstitutionAllocationView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedLimit) + Double(parsedQuantity)
    }
}
