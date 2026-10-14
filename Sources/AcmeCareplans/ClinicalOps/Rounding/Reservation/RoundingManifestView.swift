import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding manifest.
    final class RoundingManifestView {
        var code: String
        var name: String
        var approved: String
        var reviewer: String
        var phoneText: String
        var bed: String
        var attempts: String
        var retries: String
        var amountText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, approved: String, reviewer: String, phoneText: String, bed: String, attempts: String, retries: String, amountText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.approved = approved
            self.reviewer = reviewer
            self.phoneText = phoneText
            self.bed = bed
            self.attempts = attempts
            self.retries = retries
            self.amountText = amountText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingManifestView(_ item: RoundingManifest) -> RoundingManifestView {
        return RoundingManifestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            approved: "\(item.approved)",
            reviewer: item.reviewer,
            phoneText: item.phone,
            bed: item.bed,
            attempts: String(item.attempts),
            retries: String(item.retries),
            amountText: String(format: "%.2f", item.amount),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingManifestViews(_ items: [RoundingManifest]) -> [RoundingManifestView] {
        var views: [RoundingManifestView] = []
        for item in items {
            views.append(toRoundingManifestView(item))
        }
        return views
    }

    static func sumRoundingManifestView(_ view: RoundingManifestView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAttempts) + Double(parsedRetries) + parsedAmount
    }
}
