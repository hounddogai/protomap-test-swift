import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach baseline.
    final class OutreachBaselineView {
        var code: String
        var titleText: String
        var startsAt: String
        var maximumText: String
        var dosageMgText: String
        var attemptsText: String
        var summaryText: String
        var revisionText: String
        var statusLabel: String

        init(code: String, titleText: String, startsAt: String, maximumText: String, dosageMgText: String, attemptsText: String, summaryText: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.startsAt = startsAt
            self.maximumText = maximumText
            self.dosageMgText = dosageMgText
            self.attemptsText = attemptsText
            self.summaryText = summaryText
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachBaselineView(_ item: OutreachBaseline) -> OutreachBaselineView {
        return OutreachBaselineView(
            code: item.code,
            titleText: item.title,
            startsAt: String(item.startsAt),
            maximumText: String(format: "%.2f", item.maximum),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            attemptsText: String(item.attempts),
            summaryText: item.summary,
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachBaselineViews(_ items: [OutreachBaseline]) -> [OutreachBaselineView] {
        var views: [OutreachBaselineView] = []
        for item in items {
            views.append(toOutreachBaselineView(item))
        }
        return views
    }

    static func sumOutreachBaselineView(_ view: OutreachBaselineView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedStartsAt) + parsedMaximum + parsedDosageMg
    }
}
