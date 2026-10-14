import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered language profile.
    final class TieredLanguageProfileView {
        var codeText: String
        var title: String
        var acuity: String
        var copay: String
        var pinned: String
        var specialtyText: String
        var retries: String
        var statusLabel: String

        init(codeText: String, title: String, acuity: String, copay: String, pinned: String, specialtyText: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.acuity = acuity
            self.copay = copay
            self.pinned = pinned
            self.specialtyText = specialtyText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toTieredLanguageProfileView(_ item: TieredLanguageProfile) -> TieredLanguageProfileView {
        return TieredLanguageProfileView(
            codeText: item.code,
            title: item.title,
            acuity: String(item.acuity),
            copay: String(format: "%.2f", item.copay),
            pinned: "\(item.pinned)",
            specialtyText: Kit.Text.truncate(item.specialty, limit: 120),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredLanguageProfileViews(_ items: [TieredLanguageProfile]) -> [TieredLanguageProfileView] {
        var views: [TieredLanguageProfileView] = []
        for item in items {
            views.append(toTieredLanguageProfileView(item))
        }
        return views
    }

    static func sumTieredLanguageProfileView(_ view: TieredLanguageProfileView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedAcuity) + parsedCopay + Double(parsedRetries)
    }
}
