import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction score.
    final class InteractionScoreView {
        var codeText: String
        var labelText: String
        var rate: String
        var phone: String
        var source: String
        var weight: String
        var windowDays: String
        var checksum: String
        var wardText: String
        var descriptionText: String
        var statusLabel: String

        init(codeText: String, labelText: String, rate: String, phone: String, source: String, weight: String, windowDays: String, checksum: String, wardText: String, descriptionText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.rate = rate
            self.phone = phone
            self.source = source
            self.weight = weight
            self.windowDays = windowDays
            self.checksum = checksum
            self.wardText = wardText
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionScoreView(_ item: InteractionScore) -> InteractionScoreView {
        return InteractionScoreView(
            codeText: item.code,
            labelText: item.label,
            rate: String(format: "%.2f", item.rate),
            phone: item.phone,
            source: item.source,
            weight: String(format: "%.2f", item.weight),
            windowDays: String(item.windowDays),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            wardText: item.ward,
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionScoreViews(_ items: [InteractionScore]) -> [InteractionScoreView] {
        var views: [InteractionScoreView] = []
        for item in items {
            views.append(toInteractionScoreView(item))
        }
        return views
    }

    static func sumInteractionScoreView(_ view: InteractionScoreView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedRate + parsedWeight + Double(parsedWindowDays)
    }
}
