import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan notice.
    final class AcuityPlanNoticeView {
        var code: String
        var labelText: String
        var weightText: String
        var endsAt: String
        var clinicianID: String
        var startsAt: String
        var statusLabel: String

        init(code: String, labelText: String, weightText: String, endsAt: String, clinicianID: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.weightText = weightText
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanNoticeView(_ item: AcuityPlanNotice) -> AcuityPlanNoticeView {
        return AcuityPlanNoticeView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            weightText: String(format: "%.2f", item.weight),
            endsAt: String(item.endsAt),
            clinicianID: item.clinicianID,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanNoticeViews(_ items: [AcuityPlanNotice]) -> [AcuityPlanNoticeView] {
        var views: [AcuityPlanNoticeView] = []
        for item in items {
            views.append(toAcuityPlanNoticeView(item))
        }
        return views
    }

    static func sumAcuityPlanNoticeView(_ view: AcuityPlanNoticeView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedWeight + Double(parsedEndsAt) + Double(parsedStartsAt)
    }
}
