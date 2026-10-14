import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense record.
    final class DispenseRecordView {
        var codeText: String
        var name: String
        var ownerID: String
        var score: String
        var copayText: String
        var statusLabel: String

        init(codeText: String, name: String, ownerID: String, score: String, copayText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ownerID = ownerID
            self.score = score
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseRecordView(_ item: DispenseRecord) -> DispenseRecordView {
        return DispenseRecordView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            score: String(format: "%.2f", item.score),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseRecordViews(_ items: [DispenseRecord]) -> [DispenseRecordView] {
        var views: [DispenseRecordView] = []
        for item in items {
            views.append(toDispenseRecordView(item))
        }
        return views
    }

    static func sumDispenseRecordView(_ view: DispenseRecordView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedScore + parsedCopay
    }
}
