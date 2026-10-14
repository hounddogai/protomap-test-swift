import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling cleaning record.
    final class RollingCleaningRecordView {
        var codeText: String
        var titleText: String
        var segment: String
        var score: String
        var maximum: String
        var ward: String
        var floorValueText: String
        var summaryText: String
        var revision: String
        var statusLabel: String

        init(codeText: String, titleText: String, segment: String, score: String, maximum: String, ward: String, floorValueText: String, summaryText: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.segment = segment
            self.score = score
            self.maximum = maximum
            self.ward = ward
            self.floorValueText = floorValueText
            self.summaryText = summaryText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCleaningRecordView(_ item: RollingCleaningRecord) -> RollingCleaningRecordView {
        return RollingCleaningRecordView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            score: String(format: "%.2f", item.score),
            maximum: String(format: "%.2f", item.maximum),
            ward: item.ward,
            floorValueText: String(format: "%.2f", item.floorValue),
            summaryText: item.summary,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCleaningRecordViews(_ items: [RollingCleaningRecord]) -> [RollingCleaningRecordView] {
        var views: [RollingCleaningRecordView] = []
        for item in items {
            views.append(toRollingCleaningRecordView(item))
        }
        return views
    }

    static func sumRollingCleaningRecordView(_ view: RollingCleaningRecordView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedScore + parsedMaximum + parsedFloorValue
    }
}
