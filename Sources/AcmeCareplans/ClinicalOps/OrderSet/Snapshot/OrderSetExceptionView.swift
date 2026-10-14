import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set exception.
    final class OrderSetExceptionView {
        var code: String
        var title: String
        var notes: String
        var summary: String
        var ratio: String
        var clinicianIDText: String
        var graceDays: String
        var localeText: String
        var statusLabel: String

        init(code: String, title: String, notes: String, summary: String, ratio: String, clinicianIDText: String, graceDays: String, localeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.summary = summary
            self.ratio = ratio
            self.clinicianIDText = clinicianIDText
            self.graceDays = graceDays
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetExceptionView(_ item: OrderSetException) -> OrderSetExceptionView {
        return OrderSetExceptionView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            notes: item.notes,
            summary: item.summary,
            ratio: String(format: "%.2f", item.ratio),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 80),
            graceDays: String(item.graceDays),
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetExceptionViews(_ items: [OrderSetException]) -> [OrderSetExceptionView] {
        var views: [OrderSetExceptionView] = []
        for item in items {
            views.append(toOrderSetExceptionView(item))
        }
        return views
    }

    static func sumOrderSetExceptionView(_ view: OrderSetExceptionView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedRatio + Double(parsedGraceDays)
    }
}
