import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol group.
    final class CareProtocolGroupView {
        var code: String
        var label: String
        var createdAt: String
        var capacityText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, capacityText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.capacityText = capacityText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolGroupView(_ item: CareProtocolGroup) -> CareProtocolGroupView {
        return CareProtocolGroupView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            createdAt: String(item.createdAt),
            capacityText: String(item.capacity),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolGroupViews(_ items: [CareProtocolGroup]) -> [CareProtocolGroupView] {
        var views: [CareProtocolGroupView] = []
        for item in items {
            views.append(toCareProtocolGroupView(item))
        }
        return views
    }

    static func sumCareProtocolGroupView(_ view: CareProtocolGroupView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedCapacity) + parsedFloorValue
    }
}
