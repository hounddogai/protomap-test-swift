import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default referral mapping.
    final class DefaultReferralMappingView {
        var code: String
        var labelText: String
        var region: String
        var copay: String
        var externalRef: String
        var statusLabel: String

        init(code: String, labelText: String, region: String, copay: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.region = region
            self.copay = copay
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultReferralMappingView(_ item: DefaultReferralMapping) -> DefaultReferralMappingView {
        return DefaultReferralMappingView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            region: item.region,
            copay: String(format: "%.2f", item.copay),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultReferralMappingViews(_ items: [DefaultReferralMapping]) -> [DefaultReferralMappingView] {
        var views: [DefaultReferralMappingView] = []
        for item in items {
            views.append(toDefaultReferralMappingView(item))
        }
        return views
    }

    static func sumDefaultReferralMappingView(_ view: DefaultReferralMappingView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
