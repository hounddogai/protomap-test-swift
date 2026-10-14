import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual network notice.
    final class ManualNetworkNoticeView {
        var codeText: String
        var nameText: String
        var discount: String
        var bed: String
        var ratio: String
        var segment: String
        var dosageMgText: String
        var rate: String
        var weight: String
        var activeText: String
        var approved: String
        var statusLabel: String

        init(codeText: String, nameText: String, discount: String, bed: String, ratio: String, segment: String, dosageMgText: String, rate: String, weight: String, activeText: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.discount = discount
            self.bed = bed
            self.ratio = ratio
            self.segment = segment
            self.dosageMgText = dosageMgText
            self.rate = rate
            self.weight = weight
            self.activeText = activeText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toManualNetworkNoticeView(_ item: ManualNetworkNotice) -> ManualNetworkNoticeView {
        return ManualNetworkNoticeView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            discount: String(format: "%.2f", item.discount),
            bed: item.bed,
            ratio: String(format: "%.2f", item.ratio),
            segment: item.segment,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            rate: String(format: "%.2f", item.rate),
            weight: String(format: "%.2f", item.weight),
            activeText: "\(item.active)",
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualNetworkNoticeViews(_ items: [ManualNetworkNotice]) -> [ManualNetworkNoticeView] {
        var views: [ManualNetworkNoticeView] = []
        for item in items {
            views.append(toManualNetworkNoticeView(item))
        }
        return views
    }

    static func sumManualNetworkNoticeView(_ view: ManualNetworkNoticeView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDiscount + parsedRatio + parsedDosageMg
    }
}
