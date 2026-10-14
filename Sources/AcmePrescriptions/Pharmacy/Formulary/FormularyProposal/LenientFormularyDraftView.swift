import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient formulary draft.
    final class LenientFormularyDraftView {
        var code: String
        var name: String
        var retries: String
        var timezoneText: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, retries: String, timezoneText: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retries = retries
            self.timezoneText = timezoneText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toLenientFormularyDraftView(_ item: LenientFormularyDraft) -> LenientFormularyDraftView {
        return LenientFormularyDraftView(
            code: item.code,
            name: item.name,
            retries: String(item.retries),
            timezoneText: item.timezone,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientFormularyDraftViews(_ items: [LenientFormularyDraft]) -> [LenientFormularyDraftView] {
        var views: [LenientFormularyDraftView] = []
        for item in items {
            views.append(toLenientFormularyDraftView(item))
        }
        return views
    }

    static func sumLenientFormularyDraftView(_ view: LenientFormularyDraftView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRetries) + parsedRate
    }
}
