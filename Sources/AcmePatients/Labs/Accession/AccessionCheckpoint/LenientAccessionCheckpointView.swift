import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient accession checkpoint.
    final class LenientAccessionCheckpointView {
        var code: String
        var name: String
        var channelText: String
        var floorValue: String
        var expiresAt: String
        var currencyText: String
        var ratio: String
        var statusLabel: String

        init(code: String, name: String, channelText: String, floorValue: String, expiresAt: String, currencyText: String, ratio: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.channelText = channelText
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.currencyText = currencyText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAccessionCheckpointView(_ item: LenientAccessionCheckpoint) -> LenientAccessionCheckpointView {
        return LenientAccessionCheckpointView(
            code: item.code,
            name: item.name,
            channelText: item.channel,
            floorValue: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAccessionCheckpointViews(_ items: [LenientAccessionCheckpoint]) -> [LenientAccessionCheckpointView] {
        var views: [LenientAccessionCheckpointView] = []
        for item in items {
            views.append(toLenientAccessionCheckpointView(item))
        }
        return views
    }

    static func sumLenientAccessionCheckpointView(_ view: LenientAccessionCheckpointView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedFloorValue + Double(parsedExpiresAt) + parsedRatio
    }
}
