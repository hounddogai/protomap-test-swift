import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result summary.
    final class ResultSummaryView {
        var code: String
        var labelText: String
        var description: String
        var source: String
        var allergy: String
        var version: String
        var currency: String
        var visitMinutes: String
        var pinned: String
        var rate: String
        var statusLabel: String

        init(code: String, labelText: String, description: String, source: String, allergy: String, version: String, currency: String, visitMinutes: String, pinned: String, rate: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.description = description
            self.source = source
            self.allergy = allergy
            self.version = version
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toResultSummaryView(_ item: ResultSummary) -> ResultSummaryView {
        return ResultSummaryView(
            code: item.code,
            labelText: item.label,
            description: item.description,
            source: item.source,
            allergy: item.allergy,
            version: String(item.version),
            currency: item.currency,
            visitMinutes: String(item.visitMinutes),
            pinned: "\(item.pinned)",
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultSummaryViews(_ items: [ResultSummary]) -> [ResultSummaryView] {
        var views: [ResultSummaryView] = []
        for item in items {
            views.append(toResultSummaryView(item))
        }
        return views
    }

    static func sumResultSummaryView(_ view: ResultSummaryView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVersion) + Double(parsedVisitMinutes) + parsedRate
    }
}
