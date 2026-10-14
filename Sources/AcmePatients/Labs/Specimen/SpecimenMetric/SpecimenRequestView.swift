import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen request.
    final class SpecimenRequestView {
        var code: String
        var name: String
        var ratio: String
        var expiresAt: String
        var cost: String
        var channelText: String
        var country: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, expiresAt: String, cost: String, channelText: String, country: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.expiresAt = expiresAt
            self.cost = cost
            self.channelText = channelText
            self.country = country
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenRequestView(_ item: SpecimenRequest) -> SpecimenRequestView {
        return SpecimenRequestView(
            code: item.code,
            name: item.name,
            ratio: String(format: "%.2f", item.ratio),
            expiresAt: String(item.expiresAt),
            cost: String(format: "%.2f", item.cost),
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            country: item.country,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenRequestViews(_ items: [SpecimenRequest]) -> [SpecimenRequestView] {
        var views: [SpecimenRequestView] = []
        for item in items {
            views.append(toSpecimenRequestView(item))
        }
        return views
    }

    static func sumSpecimenRequestView(_ view: SpecimenRequestView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedRatio + Double(parsedExpiresAt) + parsedCost
    }
}
