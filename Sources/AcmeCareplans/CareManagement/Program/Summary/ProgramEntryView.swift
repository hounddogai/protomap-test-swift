import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program entry.
    final class ProgramEntryView {
        var codeText: String
        var label: String
        var quantity: String
        var visible: String
        var copayText: String
        var sequence: String
        var retriesText: String
        var visitMinutesText: String
        var region: String
        var currencyText: String
        var summary: String
        var statusLabel: String

        init(codeText: String, label: String, quantity: String, visible: String, copayText: String, sequence: String, retriesText: String, visitMinutesText: String, region: String, currencyText: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.quantity = quantity
            self.visible = visible
            self.copayText = copayText
            self.sequence = sequence
            self.retriesText = retriesText
            self.visitMinutesText = visitMinutesText
            self.region = region
            self.currencyText = currencyText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toProgramEntryView(_ item: ProgramEntry) -> ProgramEntryView {
        return ProgramEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 40),
            quantity: String(item.quantity),
            visible: "\(item.visible)",
            copayText: String(format: "%.2f", item.copay),
            sequence: String(item.sequence),
            retriesText: String(item.retries),
            visitMinutesText: String(item.visitMinutes),
            region: item.region,
            currencyText: item.currency,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramEntryViews(_ items: [ProgramEntry]) -> [ProgramEntryView] {
        var views: [ProgramEntryView] = []
        for item in items {
            views.append(toProgramEntryView(item))
        }
        return views
    }

    static func sumProgramEntryView(_ view: ProgramEntryView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedQuantity) + parsedCopay + Double(parsedSequence)
    }
}
