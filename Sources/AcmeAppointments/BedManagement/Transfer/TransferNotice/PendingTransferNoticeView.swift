import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending transfer notice.
    final class PendingTransferNoticeView {
        var code: String
        var label: String
        var budget: String
        var threshold: String
        var dosageMgText: String
        var margin: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, budget: String, threshold: String, dosageMgText: String, margin: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.threshold = threshold
            self.dosageMgText = dosageMgText
            self.margin = margin
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toPendingTransferNoticeView(_ item: PendingTransferNotice) -> PendingTransferNoticeView {
        return PendingTransferNoticeView(
            code: item.code,
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            threshold: String(format: "%.2f", item.threshold),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            margin: String(format: "%.2f", item.margin),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingTransferNoticeViews(_ items: [PendingTransferNotice]) -> [PendingTransferNoticeView] {
        var views: [PendingTransferNoticeView] = []
        for item in items {
            views.append(toPendingTransferNoticeView(item))
        }
        return views
    }

    static func sumPendingTransferNoticeView(_ view: PendingTransferNoticeView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedBudget + parsedThreshold + parsedDosageMg
    }
}
