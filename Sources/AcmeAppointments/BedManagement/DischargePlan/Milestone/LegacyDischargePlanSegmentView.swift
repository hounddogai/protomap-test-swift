import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy discharge plan segment.
    final class LegacyDischargePlanSegmentView {
        var code: String
        var title: String
        var externalRef: String
        var refills: String
        var ratio: String
        var unit: String
        var batchSize: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, externalRef: String, refills: String, ratio: String, unit: String, batchSize: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.refills = refills
            self.ratio = ratio
            self.unit = unit
            self.batchSize = batchSize
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDischargePlanSegmentView(_ item: LegacyDischargePlanSegment) -> LegacyDischargePlanSegmentView {
        return LegacyDischargePlanSegmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            externalRef: item.externalRef,
            refills: String(item.refills),
            ratio: String(format: "%.2f", item.ratio),
            unit: item.unit,
            batchSize: String(item.batchSize),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDischargePlanSegmentViews(_ items: [LegacyDischargePlanSegment]) -> [LegacyDischargePlanSegmentView] {
        var views: [LegacyDischargePlanSegmentView] = []
        for item in items {
            views.append(toLegacyDischargePlanSegmentView(item))
        }
        return views
    }

    static func sumLegacyDischargePlanSegmentView(_ view: LegacyDischargePlanSegmentView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRefills) + parsedRatio + Double(parsedBatchSize)
    }
}
