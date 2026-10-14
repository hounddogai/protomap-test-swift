import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped program notice.
    final class CappedProgramNoticeView {
        var code: String
        var name: String
        var dosageMg: String
        var amount: String
        var timezone: String
        var segment: String
        var priorityText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, dosageMg: String, amount: String, timezone: String, segment: String, priorityText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.amount = amount
            self.timezone = timezone
            self.segment = segment
            self.priorityText = priorityText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedProgramNoticeView(_ item: CappedProgramNotice) -> CappedProgramNoticeView {
        return CappedProgramNoticeView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            amount: String(format: "%.2f", item.amount),
            timezone: item.timezone,
            segment: item.segment,
            priorityText: String(item.priority),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedProgramNoticeViews(_ items: [CappedProgramNotice]) -> [CappedProgramNoticeView] {
        var views: [CappedProgramNoticeView] = []
        for item in items {
            views.append(toCappedProgramNoticeView(item))
        }
        return views
    }

    static func sumCappedProgramNoticeView(_ view: CappedProgramNoticeView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDosageMg + parsedAmount + Double(parsedPriority)
    }
}
