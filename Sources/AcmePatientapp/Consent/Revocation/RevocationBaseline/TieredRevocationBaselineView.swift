import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered revocation baseline.
    final class TieredRevocationBaselineView {
        var codeText: String
        var name: String
        var contactEmailText: String
        var label: String
        var copayText: String
        var statusLabel: String

        init(codeText: String, name: String, contactEmailText: String, label: String, copayText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.contactEmailText = contactEmailText
            self.label = label
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRevocationBaselineView(_ item: TieredRevocationBaseline) -> TieredRevocationBaselineView {
        return TieredRevocationBaselineView(
            codeText: item.code,
            name: item.name,
            contactEmailText: item.contactEmail,
            label: item.label,
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRevocationBaselineViews(_ items: [TieredRevocationBaseline]) -> [TieredRevocationBaselineView] {
        var views: [TieredRevocationBaselineView] = []
        for item in items {
            views.append(toTieredRevocationBaselineView(item))
        }
        return views
    }

    static func sumTieredRevocationBaselineView(_ view: TieredRevocationBaselineView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
