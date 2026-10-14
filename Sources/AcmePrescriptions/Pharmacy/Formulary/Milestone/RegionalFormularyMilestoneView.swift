import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional formulary milestone.
    final class RegionalFormularyMilestoneView {
        var code: String
        var label: String
        var payer: String
        var attempts: String
        var title: String
        var locale: String
        var reviewer: String
        var phone: String
        var approved: String
        var retries: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, payer: String, attempts: String, title: String, locale: String, reviewer: String, phone: String, approved: String, retries: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payer = payer
            self.attempts = attempts
            self.title = title
            self.locale = locale
            self.reviewer = reviewer
            self.phone = phone
            self.approved = approved
            self.retries = retries
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFormularyMilestoneView(_ item: RegionalFormularyMilestone) -> RegionalFormularyMilestoneView {
        return RegionalFormularyMilestoneView(
            code: item.code,
            label: item.label,
            payer: item.payer,
            attempts: String(item.attempts),
            title: item.title,
            locale: item.locale,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            phone: item.phone,
            approved: "\(item.approved)",
            retries: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFormularyMilestoneViews(_ items: [RegionalFormularyMilestone]) -> [RegionalFormularyMilestoneView] {
        var views: [RegionalFormularyMilestoneView] = []
        for item in items {
            views.append(toRegionalFormularyMilestoneView(item))
        }
        return views
    }

    static func sumRegionalFormularyMilestoneView(_ view: RegionalFormularyMilestoneView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAttempts) + Double(parsedRetries) + parsedDosageMg
    }
}
