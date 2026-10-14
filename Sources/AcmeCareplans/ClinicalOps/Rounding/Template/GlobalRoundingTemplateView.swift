import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global rounding template.
    final class GlobalRoundingTemplateView {
        var code: String
        var name: String
        var floorValue: String
        var allergy: String
        var batchSize: String
        var visible: String
        var minimum: String
        var notes: String
        var acuityText: String
        var retriesText: String
        var limitText: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, allergy: String, batchSize: String, visible: String, minimum: String, notes: String, acuityText: String, retriesText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.allergy = allergy
            self.batchSize = batchSize
            self.visible = visible
            self.minimum = minimum
            self.notes = notes
            self.acuityText = acuityText
            self.retriesText = retriesText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRoundingTemplateView(_ item: GlobalRoundingTemplate) -> GlobalRoundingTemplateView {
        return GlobalRoundingTemplateView(
            code: item.code,
            name: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            allergy: item.allergy,
            batchSize: String(item.batchSize),
            visible: "\(item.visible)",
            minimum: String(format: "%.2f", item.minimum),
            notes: item.notes,
            acuityText: String(item.acuity),
            retriesText: String(item.retries),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRoundingTemplateViews(_ items: [GlobalRoundingTemplate]) -> [GlobalRoundingTemplateView] {
        var views: [GlobalRoundingTemplateView] = []
        for item in items {
            views.append(toGlobalRoundingTemplateView(item))
        }
        return views
    }

    static func sumGlobalRoundingTemplateView(_ view: GlobalRoundingTemplateView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedFloorValue + Double(parsedBatchSize) + parsedMinimum
    }
}
