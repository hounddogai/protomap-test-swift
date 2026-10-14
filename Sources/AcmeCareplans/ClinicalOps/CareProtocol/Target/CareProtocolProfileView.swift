import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol profile.
    final class CareProtocolProfileView {
        var code: String
        var label: String
        var approved: String
        var active: String
        var channelText: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, approved: String, active: String, channelText: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.approved = approved
            self.active = active
            self.channelText = channelText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolProfileView(_ item: CareProtocolProfile) -> CareProtocolProfileView {
        return CareProtocolProfileView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            approved: "\(item.approved)",
            active: "\(item.active)",
            channelText: item.channel,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolProfileViews(_ items: [CareProtocolProfile]) -> [CareProtocolProfileView] {
        var views: [CareProtocolProfileView] = []
        for item in items {
            views.append(toCareProtocolProfileView(item))
        }
        return views
    }

    static func sumCareProtocolProfileView(_ view: CareProtocolProfileView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
