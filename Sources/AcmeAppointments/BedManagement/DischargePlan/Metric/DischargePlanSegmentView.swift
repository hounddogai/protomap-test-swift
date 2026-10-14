import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan segment.
    final class DischargePlanSegmentView {
        var code: String
        var nameText: String
        var clinicianID: String
        var floorValue: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, nameText: String, clinicianID: String, floorValue: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanSegmentView(_ item: DischargePlanSegment) -> DischargePlanSegmentView {
        return DischargePlanSegmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            clinicianID: item.clinicianID,
            floorValue: String(format: "%.2f", item.floorValue),
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanSegmentViews(_ items: [DischargePlanSegment]) -> [DischargePlanSegmentView] {
        var views: [DischargePlanSegmentView] = []
        for item in items {
            views.append(toDischargePlanSegmentView(item))
        }
        return views
    }

    static func sumDischargePlanSegmentView(_ view: DischargePlanSegmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
