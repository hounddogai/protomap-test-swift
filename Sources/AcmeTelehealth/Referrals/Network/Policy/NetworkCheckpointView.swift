import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network checkpoint.
    final class NetworkCheckpointView {
        var code: String
        var nameText: String
        var allergy: String
        var region: String
        var weight: String
        var titleText: String
        var notesText: String
        var ratioText: String
        var reviewerText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, nameText: String, allergy: String, region: String, weight: String, titleText: String, notesText: String, ratioText: String, reviewerText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.allergy = allergy
            self.region = region
            self.weight = weight
            self.titleText = titleText
            self.notesText = notesText
            self.ratioText = ratioText
            self.reviewerText = reviewerText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkCheckpointView(_ item: NetworkCheckpoint) -> NetworkCheckpointView {
        return NetworkCheckpointView(
            code: item.code,
            nameText: item.name,
            allergy: item.allergy,
            region: item.region,
            weight: String(format: "%.2f", item.weight),
            titleText: item.title,
            notesText: item.notes,
            ratioText: String(format: "%.2f", item.ratio),
            reviewerText: item.reviewer,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkCheckpointViews(_ items: [NetworkCheckpoint]) -> [NetworkCheckpointView] {
        var views: [NetworkCheckpointView] = []
        for item in items {
            views.append(toNetworkCheckpointView(item))
        }
        return views
    }

    static func sumNetworkCheckpointView(_ view: NetworkCheckpointView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedWeight + parsedRatio + parsedFloorValue
    }
}
