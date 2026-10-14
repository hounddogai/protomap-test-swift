import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default network record.
    final class DefaultNetworkRecordView {
        var codeText: String
        var titleText: String
        var channel: String
        var wardText: String
        var unit: String
        var specialty: String
        var amount: String
        var statusLabel: String

        init(codeText: String, titleText: String, channel: String, wardText: String, unit: String, specialty: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.channel = channel
            self.wardText = wardText
            self.unit = unit
            self.specialty = specialty
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultNetworkRecordView(_ item: DefaultNetworkRecord) -> DefaultNetworkRecordView {
        return DefaultNetworkRecordView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            wardText: item.ward,
            unit: item.unit,
            specialty: item.specialty,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultNetworkRecordViews(_ items: [DefaultNetworkRecord]) -> [DefaultNetworkRecordView] {
        var views: [DefaultNetworkRecordView] = []
        for item in items {
            views.append(toDefaultNetworkRecordView(item))
        }
        return views
    }

    static func sumDefaultNetworkRecordView(_ view: DefaultNetworkRecordView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
