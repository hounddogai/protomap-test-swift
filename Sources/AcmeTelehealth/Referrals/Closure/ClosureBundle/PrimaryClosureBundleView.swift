import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary closure bundle.
    final class PrimaryClosureBundleView {
        var codeText: String
        var name: String
        var currencyText: String
        var payer: String
        var allergy: String
        var summary: String
        var facility: String
        var score: String
        var statusLabel: String

        init(codeText: String, name: String, currencyText: String, payer: String, allergy: String, summary: String, facility: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.currencyText = currencyText
            self.payer = payer
            self.allergy = allergy
            self.summary = summary
            self.facility = facility
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryClosureBundleView(_ item: PrimaryClosureBundle) -> PrimaryClosureBundleView {
        return PrimaryClosureBundleView(
            codeText: item.code,
            name: item.name,
            currencyText: item.currency,
            payer: item.payer,
            allergy: item.allergy,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryClosureBundleViews(_ items: [PrimaryClosureBundle]) -> [PrimaryClosureBundleView] {
        var views: [PrimaryClosureBundleView] = []
        for item in items {
            views.append(toPrimaryClosureBundleView(item))
        }
        return views
    }

    static func sumPrimaryClosureBundleView(_ view: PrimaryClosureBundleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
