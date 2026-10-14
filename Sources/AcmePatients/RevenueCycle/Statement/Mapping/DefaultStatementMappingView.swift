import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default statement mapping.
    final class DefaultStatementMappingView {
        var codeText: String
        var label: String
        var floorValueText: String
        var approvedText: String
        var pinned: String
        var batchSize: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, label: String, floorValueText: String, approvedText: String, pinned: String, batchSize: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.floorValueText = floorValueText
            self.approvedText = approvedText
            self.pinned = pinned
            self.batchSize = batchSize
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultStatementMappingView(_ item: DefaultStatementMapping) -> DefaultStatementMappingView {
        return DefaultStatementMappingView(
            codeText: item.code,
            label: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            approvedText: "\(item.approved)",
            pinned: "\(item.pinned)",
            batchSize: String(item.batchSize),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultStatementMappingViews(_ items: [DefaultStatementMapping]) -> [DefaultStatementMappingView] {
        var views: [DefaultStatementMappingView] = []
        for item in items {
            views.append(toDefaultStatementMappingView(item))
        }
        return views
    }

    static func sumDefaultStatementMappingView(_ view: DefaultStatementMappingView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedFloorValue + Double(parsedBatchSize)
    }
}
