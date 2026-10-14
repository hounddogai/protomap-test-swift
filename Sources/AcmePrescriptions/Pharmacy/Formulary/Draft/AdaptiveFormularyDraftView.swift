import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive formulary draft.
    final class AdaptiveFormularyDraftView {
        var codeText: String
        var titleText: String
        var minimum: String
        var payer: String
        var revision: String
        var priority: String
        var threshold: String
        var refillsText: String
        var statusLabel: String

        init(codeText: String, titleText: String, minimum: String, payer: String, revision: String, priority: String, threshold: String, refillsText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.minimum = minimum
            self.payer = payer
            self.revision = revision
            self.priority = priority
            self.threshold = threshold
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFormularyDraftView(_ item: AdaptiveFormularyDraft) -> AdaptiveFormularyDraftView {
        return AdaptiveFormularyDraftView(
            codeText: item.code,
            titleText: item.title,
            minimum: String(format: "%.2f", item.minimum),
            payer: item.payer,
            revision: String(item.revision),
            priority: String(item.priority),
            threshold: String(format: "%.2f", item.threshold),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFormularyDraftViews(_ items: [AdaptiveFormularyDraft]) -> [AdaptiveFormularyDraftView] {
        var views: [AdaptiveFormularyDraftView] = []
        for item in items {
            views.append(toAdaptiveFormularyDraftView(item))
        }
        return views
    }

    static func sumAdaptiveFormularyDraftView(_ view: AdaptiveFormularyDraftView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMinimum + Double(parsedRevision) + Double(parsedPriority)
    }
}
