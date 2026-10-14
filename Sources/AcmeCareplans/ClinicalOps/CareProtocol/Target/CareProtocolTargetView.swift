import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol target.
    final class CareProtocolTargetView {
        var codeText: String
        var title: String
        var externalRefText: String
        var updatedAt: String
        var channel: String
        var durationMinutesText: String
        var payer: String
        var category: String
        var statusLabel: String

        init(codeText: String, title: String, externalRefText: String, updatedAt: String, channel: String, durationMinutesText: String, payer: String, category: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.externalRefText = externalRefText
            self.updatedAt = updatedAt
            self.channel = channel
            self.durationMinutesText = durationMinutesText
            self.payer = payer
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolTargetView(_ item: CareProtocolTarget) -> CareProtocolTargetView {
        return CareProtocolTargetView(
            codeText: item.code,
            title: item.title,
            externalRefText: item.externalRef,
            updatedAt: String(item.updatedAt),
            channel: item.channel,
            durationMinutesText: String(item.durationMinutes),
            payer: item.payer,
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolTargetViews(_ items: [CareProtocolTarget]) -> [CareProtocolTargetView] {
        var views: [CareProtocolTargetView] = []
        for item in items {
            views.append(toCareProtocolTargetView(item))
        }
        return views
    }

    static func sumCareProtocolTargetView(_ view: CareProtocolTargetView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedDurationMinutes)
    }
}
