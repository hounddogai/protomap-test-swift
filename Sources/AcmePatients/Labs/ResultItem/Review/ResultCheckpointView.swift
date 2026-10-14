import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result checkpoint.
    final class ResultCheckpointView {
        var codeText: String
        var name: String
        var checksumText: String
        var externalRef: String
        var source: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, checksumText: String, externalRef: String, source: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.checksumText = checksumText
            self.externalRef = externalRef
            self.source = source
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toResultCheckpointView(_ item: ResultCheckpoint) -> ResultCheckpointView {
        return ResultCheckpointView(
            codeText: item.code,
            name: item.name,
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            externalRef: item.externalRef,
            source: item.source,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultCheckpointViews(_ items: [ResultCheckpoint]) -> [ResultCheckpointView] {
        var views: [ResultCheckpointView] = []
        for item in items {
            views.append(toResultCheckpointView(item))
        }
        return views
    }

    static func sumResultCheckpointView(_ view: ResultCheckpointView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
