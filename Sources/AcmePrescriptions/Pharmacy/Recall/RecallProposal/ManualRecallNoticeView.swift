import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall notice.
    final class ManualRecallNoticeView {
        var code: String
        var label: String
        var locale: String
        var bed: String
        var region: String
        var versionText: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, locale: String, bed: String, region: String, versionText: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.locale = locale
            self.bed = bed
            self.region = region
            self.versionText = versionText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallNoticeView(_ item: ManualRecallNotice) -> ManualRecallNoticeView {
        return ManualRecallNoticeView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            locale: item.locale,
            bed: item.bed,
            region: Kit.Text.truncate(item.region, limit: 80),
            versionText: String(item.version),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallNoticeViews(_ items: [ManualRecallNotice]) -> [ManualRecallNoticeView] {
        var views: [ManualRecallNoticeView] = []
        for item in items {
            views.append(toManualRecallNoticeView(item))
        }
        return views
    }

    static func sumManualRecallNoticeView(_ view: ManualRecallNoticeView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedVersion) + parsedAmount
    }
}
