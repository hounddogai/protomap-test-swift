import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal disclosure cycle.
    final class SeasonalDisclosureCycleView {
        var codeText: String
        var title: String
        var rate: String
        var notes: String
        var acuity: String
        var segmentText: String
        var category: String
        var archivedText: String
        var statusLabel: String

        init(codeText: String, title: String, rate: String, notes: String, acuity: String, segmentText: String, category: String, archivedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.rate = rate
            self.notes = notes
            self.acuity = acuity
            self.segmentText = segmentText
            self.category = category
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalDisclosureCycleView(_ item: SeasonalDisclosureCycle) -> SeasonalDisclosureCycleView {
        return SeasonalDisclosureCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            rate: String(format: "%.2f", item.rate),
            notes: item.notes,
            acuity: String(item.acuity),
            segmentText: item.segment,
            category: item.category,
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalDisclosureCycleViews(_ items: [SeasonalDisclosureCycle]) -> [SeasonalDisclosureCycleView] {
        var views: [SeasonalDisclosureCycleView] = []
        for item in items {
            views.append(toSeasonalDisclosureCycleView(item))
        }
        return views
    }

    static func sumSeasonalDisclosureCycleView(_ view: SeasonalDisclosureCycleView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRate + Double(parsedAcuity)
    }
}
