import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient acuity plan baseline.
    final class LenientAcuityPlanBaselineView {
        var code: String
        var labelText: String
        var createdAt: String
        var startsAtText: String
        var payer: String
        var ward: String
        var summary: String
        var statusLabel: String

        init(code: String, labelText: String, createdAt: String, startsAtText: String, payer: String, ward: String, summary: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.createdAt = createdAt
            self.startsAtText = startsAtText
            self.payer = payer
            self.ward = ward
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAcuityPlanBaselineView(_ item: LenientAcuityPlanBaseline) -> LenientAcuityPlanBaselineView {
        return LenientAcuityPlanBaselineView(
            code: item.code,
            labelText: item.label,
            createdAt: String(item.createdAt),
            startsAtText: String(item.startsAt),
            payer: item.payer,
            ward: Kit.Text.truncate(item.ward, limit: 64),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAcuityPlanBaselineViews(_ items: [LenientAcuityPlanBaseline]) -> [LenientAcuityPlanBaselineView] {
        var views: [LenientAcuityPlanBaselineView] = []
        for item in items {
            views.append(toLenientAcuityPlanBaselineView(item))
        }
        return views
    }

    static func sumLenientAcuityPlanBaselineView(_ view: LenientAcuityPlanBaselineView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
