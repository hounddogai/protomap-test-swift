import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback disclosure agreement.
    final class FallbackDisclosureAgreementView {
        var code: String
        var title: String
        var archived: String
        var category: String
        var refillsText: String
        var externalRef: String
        var windowDays: String
        var phone: String
        var score: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, title: String, archived: String, category: String, refillsText: String, externalRef: String, windowDays: String, phone: String, score: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archived = archived
            self.category = category
            self.refillsText = refillsText
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.phone = phone
            self.score = score
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDisclosureAgreementView(_ item: FallbackDisclosureAgreement) -> FallbackDisclosureAgreementView {
        return FallbackDisclosureAgreementView(
            code: item.code,
            title: item.title,
            archived: "\(item.archived)",
            category: Kit.Text.truncate(item.category, limit: 40),
            refillsText: String(item.refills),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            windowDays: String(item.windowDays),
            phone: item.phone,
            score: String(format: "%.2f", item.score),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDisclosureAgreementViews(_ items: [FallbackDisclosureAgreement]) -> [FallbackDisclosureAgreementView] {
        var views: [FallbackDisclosureAgreementView] = []
        for item in items {
            views.append(toFallbackDisclosureAgreementView(item))
        }
        return views
    }

    static func sumFallbackDisclosureAgreementView(_ view: FallbackDisclosureAgreementView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRefills) + Double(parsedWindowDays) + parsedScore
    }
}
