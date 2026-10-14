import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending network bundle.
    final class PendingNetworkBundleView {
        var code: String
        var name: String
        var retries: String
        var ward: String
        var unit: String
        var statusLabel: String

        init(code: String, name: String, retries: String, ward: String, unit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retries = retries
            self.ward = ward
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toPendingNetworkBundleView(_ item: PendingNetworkBundle) -> PendingNetworkBundleView {
        return PendingNetworkBundleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            retries: String(item.retries),
            ward: item.ward,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingNetworkBundleViews(_ items: [PendingNetworkBundle]) -> [PendingNetworkBundleView] {
        var views: [PendingNetworkBundleView] = []
        for item in items {
            views.append(toPendingNetworkBundleView(item))
        }
        return views
    }

    static func sumPendingNetworkBundleView(_ view: PendingNetworkBundleView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
