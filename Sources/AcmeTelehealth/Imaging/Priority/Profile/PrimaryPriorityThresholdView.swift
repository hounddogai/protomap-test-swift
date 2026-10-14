import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary priority threshold.
    final class PrimaryPriorityThresholdView {
        var codeText: String
        var name: String
        var clinicianIDText: String
        var retries: String
        var title: String
        var rateText: String
        var attempts: String
        var sourceText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, name: String, clinicianIDText: String, retries: String, title: String, rateText: String, attempts: String, sourceText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.clinicianIDText = clinicianIDText
            self.retries = retries
            self.title = title
            self.rateText = rateText
            self.attempts = attempts
            self.sourceText = sourceText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryPriorityThresholdView(_ item: PrimaryPriorityThreshold) -> PrimaryPriorityThresholdView {
        return PrimaryPriorityThresholdView(
            codeText: item.code,
            name: item.name,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            retries: String(item.retries),
            title: item.title,
            rateText: String(format: "%.2f", item.rate),
            attempts: String(item.attempts),
            sourceText: item.source,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryPriorityThresholdViews(_ items: [PrimaryPriorityThreshold]) -> [PrimaryPriorityThresholdView] {
        var views: [PrimaryPriorityThresholdView] = []
        for item in items {
            views.append(toPrimaryPriorityThresholdView(item))
        }
        return views
    }

    static func sumPrimaryPriorityThresholdView(_ view: PrimaryPriorityThresholdView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRetries) + parsedRate + Double(parsedAttempts)
    }
}
