import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional care protocol ledger.
    final class RegionalCareProtocolLedgerView {
        var code: String
        var nameText: String
        var regionText: String
        var threshold: String
        var channelText: String
        var retriesText: String
        var approvedText: String
        var visitMinutes: String
        var checksum: String
        var payerText: String
        var visibleText: String
        var statusLabel: String

        init(code: String, nameText: String, regionText: String, threshold: String, channelText: String, retriesText: String, approvedText: String, visitMinutes: String, checksum: String, payerText: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.regionText = regionText
            self.threshold = threshold
            self.channelText = channelText
            self.retriesText = retriesText
            self.approvedText = approvedText
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.payerText = payerText
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareProtocolLedgerView(_ item: RegionalCareProtocolLedger) -> RegionalCareProtocolLedgerView {
        return RegionalCareProtocolLedgerView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            regionText: item.region,
            threshold: String(format: "%.2f", item.threshold),
            channelText: item.channel,
            retriesText: String(item.retries),
            approvedText: "\(item.approved)",
            visitMinutes: String(item.visitMinutes),
            checksum: item.checksum,
            payerText: item.payer,
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareProtocolLedgerViews(_ items: [RegionalCareProtocolLedger]) -> [RegionalCareProtocolLedgerView] {
        var views: [RegionalCareProtocolLedgerView] = []
        for item in items {
            views.append(toRegionalCareProtocolLedgerView(item))
        }
        return views
    }

    static func sumRegionalCareProtocolLedgerView(_ view: RegionalCareProtocolLedgerView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedThreshold + Double(parsedRetries) + Double(parsedVisitMinutes)
    }
}
