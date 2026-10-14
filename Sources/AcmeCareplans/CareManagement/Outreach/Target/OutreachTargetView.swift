import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach target.
    final class OutreachTargetView {
        var codeText: String
        var titleText: String
        var retries: String
        var acuity: String
        var timezone: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, titleText: String, retries: String, acuity: String, timezone: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.retries = retries
            self.acuity = acuity
            self.timezone = timezone
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachTargetView(_ item: OutreachTarget) -> OutreachTargetView {
        return OutreachTargetView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            retries: String(item.retries),
            acuity: String(item.acuity),
            timezone: item.timezone,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachTargetViews(_ items: [OutreachTarget]) -> [OutreachTargetView] {
        var views: [OutreachTargetView] = []
        for item in items {
            views.append(toOutreachTargetView(item))
        }
        return views
    }

    static func sumOutreachTargetView(_ view: OutreachTargetView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedRetries) + Double(parsedAcuity)
    }
}
