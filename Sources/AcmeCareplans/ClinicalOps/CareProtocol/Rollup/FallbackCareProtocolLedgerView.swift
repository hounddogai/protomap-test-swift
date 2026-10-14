import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback care protocol ledger.
    final class FallbackCareProtocolLedgerView {
        var codeText: String
        var nameText: String
        var encounterID: String
        var copay: String
        var diagnosisCode: String
        var priority: String
        var phoneText: String
        var windowDays: String
        var margin: String
        var statusLabel: String

        init(codeText: String, nameText: String, encounterID: String, copay: String, diagnosisCode: String, priority: String, phoneText: String, windowDays: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.encounterID = encounterID
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.phoneText = phoneText
            self.windowDays = windowDays
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolLedgerView(_ item: FallbackCareProtocolLedger) -> FallbackCareProtocolLedgerView {
        return FallbackCareProtocolLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            copay: String(format: "%.2f", item.copay),
            diagnosisCode: item.diagnosisCode,
            priority: String(item.priority),
            phoneText: item.phone,
            windowDays: String(item.windowDays),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolLedgerViews(_ items: [FallbackCareProtocolLedger]) -> [FallbackCareProtocolLedgerView] {
        var views: [FallbackCareProtocolLedgerView] = []
        for item in items {
            views.append(toFallbackCareProtocolLedgerView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolLedgerView(_ view: FallbackCareProtocolLedgerView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedCopay + Double(parsedPriority) + Double(parsedWindowDays)
    }
}
