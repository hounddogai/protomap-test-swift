import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel manifest.
    final class PanelManifestView {
        var code: String
        var labelText: String
        var limit: String
        var amount: String
        var sequenceText: String
        var discount: String
        var margin: String
        var scoreText: String
        var ceiling: String
        var ownerID: String
        var encounterID: String
        var statusLabel: String

        init(code: String, labelText: String, limit: String, amount: String, sequenceText: String, discount: String, margin: String, scoreText: String, ceiling: String, ownerID: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.limit = limit
            self.amount = amount
            self.sequenceText = sequenceText
            self.discount = discount
            self.margin = margin
            self.scoreText = scoreText
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toPanelManifestView(_ item: PanelManifest) -> PanelManifestView {
        return PanelManifestView(
            code: item.code,
            labelText: item.label,
            limit: String(item.limit),
            amount: String(format: "%.2f", item.amount),
            sequenceText: String(item.sequence),
            discount: String(format: "%.2f", item.discount),
            margin: String(format: "%.2f", item.margin),
            scoreText: String(format: "%.2f", item.score),
            ceiling: String(format: "%.2f", item.ceiling),
            ownerID: item.ownerID,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelManifestViews(_ items: [PanelManifest]) -> [PanelManifestView] {
        var views: [PanelManifestView] = []
        for item in items {
            views.append(toPanelManifestView(item))
        }
        return views
    }

    static func sumPanelManifestView(_ view: PanelManifestView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedLimit) + parsedAmount + Double(parsedSequence)
    }
}
