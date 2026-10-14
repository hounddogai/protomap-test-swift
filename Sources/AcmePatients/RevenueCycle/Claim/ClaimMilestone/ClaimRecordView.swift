import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim record.
    final class ClaimRecordView {
        var code: String
        var name: String
        var limitText: String
        var category: String
        var startsAt: String
        var ratio: String
        var payer: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, category: String, startsAt: String, ratio: String, payer: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.category = category
            self.startsAt = startsAt
            self.ratio = ratio
            self.payer = payer
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toClaimRecordView(_ item: ClaimRecord) -> ClaimRecordView {
        return ClaimRecordView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            limitText: String(item.limit),
            category: item.category,
            startsAt: String(item.startsAt),
            ratio: String(format: "%.2f", item.ratio),
            payer: item.payer,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimRecordViews(_ items: [ClaimRecord]) -> [ClaimRecordView] {
        var views: [ClaimRecordView] = []
        for item in items {
            views.append(toClaimRecordView(item))
        }
        return views
    }

    static func sumClaimRecordView(_ view: ClaimRecordView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedLimit) + Double(parsedStartsAt) + parsedRatio
    }
}
