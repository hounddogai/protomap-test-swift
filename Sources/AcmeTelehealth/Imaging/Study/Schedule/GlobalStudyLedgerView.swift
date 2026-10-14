import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global study ledger.
    final class GlobalStudyLedgerView {
        var codeText: String
        var nameText: String
        var score: String
        var ceiling: String
        var thresholdText: String
        var visitMinutesText: String
        var version: String
        var ownerIDText: String
        var phone: String
        var statusLabel: String

        init(codeText: String, nameText: String, score: String, ceiling: String, thresholdText: String, visitMinutesText: String, version: String, ownerIDText: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.score = score
            self.ceiling = ceiling
            self.thresholdText = thresholdText
            self.visitMinutesText = visitMinutesText
            self.version = version
            self.ownerIDText = ownerIDText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalStudyLedgerView(_ item: GlobalStudyLedger) -> GlobalStudyLedgerView {
        return GlobalStudyLedgerView(
            codeText: item.code,
            nameText: item.name,
            score: String(format: "%.2f", item.score),
            ceiling: String(format: "%.2f", item.ceiling),
            thresholdText: String(format: "%.2f", item.threshold),
            visitMinutesText: String(item.visitMinutes),
            version: String(item.version),
            ownerIDText: item.ownerID,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalStudyLedgerViews(_ items: [GlobalStudyLedger]) -> [GlobalStudyLedgerView] {
        var views: [GlobalStudyLedgerView] = []
        for item in items {
            views.append(toGlobalStudyLedgerView(item))
        }
        return views
    }

    static func sumGlobalStudyLedgerView(_ view: GlobalStudyLedgerView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedScore + parsedCeiling + parsedThreshold
    }
}
