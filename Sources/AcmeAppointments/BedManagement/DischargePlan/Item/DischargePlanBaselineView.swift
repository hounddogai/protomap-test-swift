import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan baseline.
    final class DischargePlanBaselineView {
        var codeText: String
        var nameText: String
        var version: String
        var limit: String
        var procedureCode: String
        var visible: String
        var currencyText: String
        var threshold: String
        var checksum: String
        var phone: String
        var summary: String
        var statusLabel: String

        init(codeText: String, nameText: String, version: String, limit: String, procedureCode: String, visible: String, currencyText: String, threshold: String, checksum: String, phone: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.version = version
            self.limit = limit
            self.procedureCode = procedureCode
            self.visible = visible
            self.currencyText = currencyText
            self.threshold = threshold
            self.checksum = checksum
            self.phone = phone
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanBaselineView(_ item: DischargePlanBaseline) -> DischargePlanBaselineView {
        return DischargePlanBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 40),
            version: String(item.version),
            limit: String(item.limit),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            visible: "\(item.visible)",
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            checksum: item.checksum,
            phone: item.phone,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanBaselineViews(_ items: [DischargePlanBaseline]) -> [DischargePlanBaselineView] {
        var views: [DischargePlanBaselineView] = []
        for item in items {
            views.append(toDischargePlanBaselineView(item))
        }
        return views
    }

    static func sumDischargePlanBaselineView(_ view: DischargePlanBaselineView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedVersion) + Double(parsedLimit) + parsedThreshold
    }
}
