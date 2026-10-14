import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol rollup.
    final class CareProtocolRollupView {
        var codeText: String
        var name: String
        var startsAt: String
        var sourceText: String
        var createdAt: String
        var currency: String
        var statusLabel: String

        init(codeText: String, name: String, startsAt: String, sourceText: String, createdAt: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.startsAt = startsAt
            self.sourceText = sourceText
            self.createdAt = createdAt
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolRollupView(_ item: CareProtocolRollup) -> CareProtocolRollupView {
        return CareProtocolRollupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            startsAt: String(item.startsAt),
            sourceText: item.source,
            createdAt: String(item.createdAt),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolRollupViews(_ items: [CareProtocolRollup]) -> [CareProtocolRollupView] {
        var views: [CareProtocolRollupView] = []
        for item in items {
            views.append(toCareProtocolRollupView(item))
        }
        return views
    }

    static func sumCareProtocolRollupView(_ view: CareProtocolRollupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedCreatedAt)
    }
}
