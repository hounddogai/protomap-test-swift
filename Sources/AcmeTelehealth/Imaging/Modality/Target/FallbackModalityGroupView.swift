import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback modality group.
    final class FallbackModalityGroupView {
        var codeText: String
        var title: String
        var maximum: String
        var unit: String
        var diagnosisCode: String
        var priority: String
        var wardText: String
        var floorValueText: String
        var description: String
        var retries: String
        var statusLabel: String

        init(codeText: String, title: String, maximum: String, unit: String, diagnosisCode: String, priority: String, wardText: String, floorValueText: String, description: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximum = maximum
            self.unit = unit
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.wardText = wardText
            self.floorValueText = floorValueText
            self.description = description
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackModalityGroupView(_ item: FallbackModalityGroup) -> FallbackModalityGroupView {
        return FallbackModalityGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            unit: item.unit,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            priority: String(item.priority),
            wardText: item.ward,
            floorValueText: String(format: "%.2f", item.floorValue),
            description: item.description,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackModalityGroupViews(_ items: [FallbackModalityGroup]) -> [FallbackModalityGroupView] {
        var views: [FallbackModalityGroupView] = []
        for item in items {
            views.append(toFallbackModalityGroupView(item))
        }
        return views
    }

    static func sumFallbackModalityGroupView(_ view: FallbackModalityGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMaximum + Double(parsedPriority) + parsedFloorValue
    }
}
