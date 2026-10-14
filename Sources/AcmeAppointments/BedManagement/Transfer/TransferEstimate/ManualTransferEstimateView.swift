import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual transfer estimate.
    final class ManualTransferEstimateView {
        var code: String
        var nameText: String
        var descriptionText: String
        var channel: String
        var createdAt: String
        var pinnedText: String
        var locale: String
        var phoneText: String
        var acuity: String
        var statusLabel: String

        init(code: String, nameText: String, descriptionText: String, channel: String, createdAt: String, pinnedText: String, locale: String, phoneText: String, acuity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.descriptionText = descriptionText
            self.channel = channel
            self.createdAt = createdAt
            self.pinnedText = pinnedText
            self.locale = locale
            self.phoneText = phoneText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toManualTransferEstimateView(_ item: ManualTransferEstimate) -> ManualTransferEstimateView {
        return ManualTransferEstimateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            descriptionText: item.description,
            channel: item.channel,
            createdAt: String(item.createdAt),
            pinnedText: "\(item.pinned)",
            locale: item.locale,
            phoneText: item.phone,
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualTransferEstimateViews(_ items: [ManualTransferEstimate]) -> [ManualTransferEstimateView] {
        var views: [ManualTransferEstimateView] = []
        for item in items {
            views.append(toManualTransferEstimateView(item))
        }
        return views
    }

    static func sumManualTransferEstimateView(_ view: ManualTransferEstimateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedAcuity)
    }
}
