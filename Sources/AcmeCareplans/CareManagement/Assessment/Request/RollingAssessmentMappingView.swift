import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling assessment mapping.
    final class RollingAssessmentMappingView {
        var codeText: String
        var nameText: String
        var score: String
        var copay: String
        var floorValue: String
        var regionText: String
        var titleText: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, nameText: String, score: String, copay: String, floorValue: String, regionText: String, titleText: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.score = score
            self.copay = copay
            self.floorValue = floorValue
            self.regionText = regionText
            self.titleText = titleText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAssessmentMappingView(_ item: RollingAssessmentMapping) -> RollingAssessmentMappingView {
        return RollingAssessmentMappingView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            score: String(format: "%.2f", item.score),
            copay: String(format: "%.2f", item.copay),
            floorValue: String(format: "%.2f", item.floorValue),
            regionText: Kit.Text.truncate(item.region, limit: 80),
            titleText: item.title,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAssessmentMappingViews(_ items: [RollingAssessmentMapping]) -> [RollingAssessmentMappingView] {
        var views: [RollingAssessmentMappingView] = []
        for item in items {
            views.append(toRollingAssessmentMappingView(item))
        }
        return views
    }

    static func sumRollingAssessmentMappingView(_ view: RollingAssessmentMappingView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedScore + parsedCopay + parsedFloorValue
    }
}
