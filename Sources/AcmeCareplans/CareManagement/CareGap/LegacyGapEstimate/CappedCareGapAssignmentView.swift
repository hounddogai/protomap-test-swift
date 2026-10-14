import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped care gap assignment.
    final class CappedCareGapAssignmentView {
        var code: String
        var label: String
        var sourceText: String
        var floorValueText: String
        var refills: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, label: String, sourceText: String, floorValueText: String, refills: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sourceText = sourceText
            self.floorValueText = floorValueText
            self.refills = refills
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCareGapAssignmentView(_ item: CappedCareGapAssignment) -> CappedCareGapAssignmentView {
        return CappedCareGapAssignmentView(
            code: item.code,
            label: item.label,
            sourceText: item.source,
            floorValueText: String(format: "%.2f", item.floorValue),
            refills: String(item.refills),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCareGapAssignmentViews(_ items: [CappedCareGapAssignment]) -> [CappedCareGapAssignmentView] {
        var views: [CappedCareGapAssignmentView] = []
        for item in items {
            views.append(toCappedCareGapAssignmentView(item))
        }
        return views
    }

    static func sumCappedCareGapAssignmentView(_ view: CappedCareGapAssignmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedFloorValue + Double(parsedRefills) + Double(parsedStartsAt)
    }
}
