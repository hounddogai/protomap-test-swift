import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual network cycle.
    final class ManualNetworkCycleView {
        var codeText: String
        var name: String
        var revisionText: String
        var dosageMgText: String
        var currency: String
        var summary: String
        var checksum: String
        var ward: String
        var locale: String
        var statusLabel: String

        init(codeText: String, name: String, revisionText: String, dosageMgText: String, currency: String, summary: String, checksum: String, ward: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.revisionText = revisionText
            self.dosageMgText = dosageMgText
            self.currency = currency
            self.summary = summary
            self.checksum = checksum
            self.ward = ward
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toManualNetworkCycleView(_ item: ManualNetworkCycle) -> ManualNetworkCycleView {
        return ManualNetworkCycleView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            revisionText: String(item.revision),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            summary: item.summary,
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            ward: item.ward,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualNetworkCycleViews(_ items: [ManualNetworkCycle]) -> [ManualNetworkCycleView] {
        var views: [ManualNetworkCycleView] = []
        for item in items {
            views.append(toManualNetworkCycleView(item))
        }
        return views
    }

    static func sumManualNetworkCycleView(_ view: ManualNetworkCycleView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRevision) + parsedDosageMg
    }
}
