import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched care protocol ledger.
    final class BatchedCareProtocolLedgerView {
        var code: String
        var label: String
        var ownerID: String
        var ratioText: String
        var active: String
        var minimumText: String
        var version: String
        var titleText: String
        var summary: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, label: String, ownerID: String, ratioText: String, active: String, minimumText: String, version: String, titleText: String, summary: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.ratioText = ratioText
            self.active = active
            self.minimumText = minimumText
            self.version = version
            self.titleText = titleText
            self.summary = summary
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareProtocolLedgerView(_ item: BatchedCareProtocolLedger) -> BatchedCareProtocolLedgerView {
        return BatchedCareProtocolLedgerView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            ownerID: item.ownerID,
            ratioText: String(format: "%.2f", item.ratio),
            active: "\(item.active)",
            minimumText: String(format: "%.2f", item.minimum),
            version: String(item.version),
            titleText: item.title,
            summary: item.summary,
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareProtocolLedgerViews(_ items: [BatchedCareProtocolLedger]) -> [BatchedCareProtocolLedgerView] {
        var views: [BatchedCareProtocolLedgerView] = []
        for item in items {
            views.append(toBatchedCareProtocolLedgerView(item))
        }
        return views
    }

    static func sumBatchedCareProtocolLedgerView(_ view: BatchedCareProtocolLedgerView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRatio + parsedMinimum + Double(parsedVersion)
    }
}
