import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach request.
    final class OutreachRequestView {
        var code: String
        var label: String
        var discount: String
        var retries: String
        var checksum: String
        var currencyText: String
        var windowDays: String
        var segment: String
        var statusLabel: String

        init(code: String, label: String, discount: String, retries: String, checksum: String, currencyText: String, windowDays: String, segment: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.retries = retries
            self.checksum = checksum
            self.currencyText = currencyText
            self.windowDays = windowDays
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachRequestView(_ item: OutreachRequest) -> OutreachRequestView {
        return OutreachRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            retries: String(item.retries),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            currencyText: item.currency,
            windowDays: String(item.windowDays),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachRequestViews(_ items: [OutreachRequest]) -> [OutreachRequestView] {
        var views: [OutreachRequestView] = []
        for item in items {
            views.append(toOutreachRequestView(item))
        }
        return views
    }

    static func sumOutreachRequestView(_ view: OutreachRequestView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedDiscount + Double(parsedRetries) + Double(parsedWindowDays)
    }
}
