import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling alert notice.
    final class RollingAlertNoticeView {
        var code: String
        var nameText: String
        var payerText: String
        var minimum: String
        var summary: String
        var revision: String
        var ratio: String
        var discount: String
        var checksum: String
        var statusLabel: String

        init(code: String, nameText: String, payerText: String, minimum: String, summary: String, revision: String, ratio: String, discount: String, checksum: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payerText = payerText
            self.minimum = minimum
            self.summary = summary
            self.revision = revision
            self.ratio = ratio
            self.discount = discount
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAlertNoticeView(_ item: RollingAlertNotice) -> RollingAlertNoticeView {
        return RollingAlertNoticeView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            payerText: item.payer,
            minimum: String(format: "%.2f", item.minimum),
            summary: item.summary,
            revision: String(item.revision),
            ratio: String(format: "%.2f", item.ratio),
            discount: String(format: "%.2f", item.discount),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAlertNoticeViews(_ items: [RollingAlertNotice]) -> [RollingAlertNoticeView] {
        var views: [RollingAlertNoticeView] = []
        for item in items {
            views.append(toRollingAlertNoticeView(item))
        }
        return views
    }

    static func sumRollingAlertNoticeView(_ view: RollingAlertNoticeView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMinimum + Double(parsedRevision) + parsedRatio
    }
}
