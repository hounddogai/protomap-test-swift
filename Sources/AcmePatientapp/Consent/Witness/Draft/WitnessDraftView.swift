import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness draft.
    final class WitnessDraftView {
        var code: String
        var label: String
        var wardText: String
        var summary: String
        var rate: String
        var score: String
        var description: String
        var refills: String
        var archivedText: String
        var statusLabel: String

        init(code: String, label: String, wardText: String, summary: String, rate: String, score: String, description: String, refills: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.wardText = wardText
            self.summary = summary
            self.rate = rate
            self.score = score
            self.description = description
            self.refills = refills
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessDraftView(_ item: WitnessDraft) -> WitnessDraftView {
        return WitnessDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            wardText: Kit.Text.truncate(item.ward, limit: 80),
            summary: item.summary,
            rate: String(format: "%.2f", item.rate),
            score: String(format: "%.2f", item.score),
            description: item.description,
            refills: String(item.refills),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessDraftViews(_ items: [WitnessDraft]) -> [WitnessDraftView] {
        var views: [WitnessDraftView] = []
        for item in items {
            views.append(toWitnessDraftView(item))
        }
        return views
    }

    static func sumWitnessDraftView(_ view: WitnessDraftView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRate + parsedScore + Double(parsedRefills)
    }
}
