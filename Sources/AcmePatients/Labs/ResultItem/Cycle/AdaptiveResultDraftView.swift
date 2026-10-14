import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive result draft.
    final class AdaptiveResultDraftView {
        var code: String
        var name: String
        var labelText: String
        var windowDays: String
        var copay: String
        var dosageMg: String
        var threshold: String
        var externalRef: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, labelText: String, windowDays: String, copay: String, dosageMg: String, threshold: String, externalRef: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.labelText = labelText
            self.windowDays = windowDays
            self.copay = copay
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.externalRef = externalRef
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveResultDraftView(_ item: AdaptiveResultDraft) -> AdaptiveResultDraftView {
        return AdaptiveResultDraftView(
            code: item.code,
            name: item.name,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            windowDays: String(item.windowDays),
            copay: String(format: "%.2f", item.copay),
            dosageMg: String(format: "%.2f", item.dosageMg),
            threshold: String(format: "%.2f", item.threshold),
            externalRef: item.externalRef,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveResultDraftViews(_ items: [AdaptiveResultDraft]) -> [AdaptiveResultDraftView] {
        var views: [AdaptiveResultDraftView] = []
        for item in items {
            views.append(toAdaptiveResultDraftView(item))
        }
        return views
    }

    static func sumAdaptiveResultDraftView(_ view: AdaptiveResultDraftView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedWindowDays) + parsedCopay + parsedDosageMg
    }
}
