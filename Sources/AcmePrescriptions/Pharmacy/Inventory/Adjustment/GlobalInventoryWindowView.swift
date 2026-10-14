import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global inventory window.
    final class GlobalInventoryWindowView {
        var codeText: String
        var labelText: String
        var clinicianID: String
        var active: String
        var batchSize: String
        var capacityText: String
        var statusLabel: String

        init(codeText: String, labelText: String, clinicianID: String, active: String, batchSize: String, capacityText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.clinicianID = clinicianID
            self.active = active
            self.batchSize = batchSize
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalInventoryWindowView(_ item: GlobalInventoryWindow) -> GlobalInventoryWindowView {
        return GlobalInventoryWindowView(
            codeText: item.code,
            labelText: item.label,
            clinicianID: item.clinicianID,
            active: "\(item.active)",
            batchSize: String(item.batchSize),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalInventoryWindowViews(_ items: [GlobalInventoryWindow]) -> [GlobalInventoryWindowView] {
        var views: [GlobalInventoryWindowView] = []
        for item in items {
            views.append(toGlobalInventoryWindowView(item))
        }
        return views
    }

    static func sumGlobalInventoryWindowView(_ view: GlobalInventoryWindowView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedCapacity)
    }
}
