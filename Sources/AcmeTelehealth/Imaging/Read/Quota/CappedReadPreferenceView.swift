import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped read preference.
    final class CappedReadPreferenceView {
        var code: String
        var title: String
        var rate: String
        var clinicianID: String
        var updatedAtText: String
        var limit: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, title: String, rate: String, clinicianID: String, updatedAtText: String, limit: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.rate = rate
            self.clinicianID = clinicianID
            self.updatedAtText = updatedAtText
            self.limit = limit
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReadPreferenceView(_ item: CappedReadPreference) -> CappedReadPreferenceView {
        return CappedReadPreferenceView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            rate: String(format: "%.2f", item.rate),
            clinicianID: item.clinicianID,
            updatedAtText: String(item.updatedAt),
            limit: String(item.limit),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReadPreferenceViews(_ items: [CappedReadPreference]) -> [CappedReadPreferenceView] {
        var views: [CappedReadPreferenceView] = []
        for item in items {
            views.append(toCappedReadPreferenceView(item))
        }
        return views
    }

    static func sumCappedReadPreferenceView(_ view: CappedReadPreferenceView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedRate + Double(parsedUpdatedAt) + Double(parsedLimit)
    }
}
