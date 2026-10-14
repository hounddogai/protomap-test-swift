import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap policy.
    final class CareGapPolicyView {
        var code: String
        var title: String
        var specialty: String
        var ratio: String
        var payer: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, specialty: String, ratio: String, payer: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.ratio = ratio
            self.payer = payer
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapPolicyView(_ item: CareGapPolicy) -> CareGapPolicyView {
        return CareGapPolicyView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            specialty: item.specialty,
            ratio: String(format: "%.2f", item.ratio),
            payer: item.payer,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapPolicyViews(_ items: [CareGapPolicy]) -> [CareGapPolicyView] {
        var views: [CareGapPolicyView] = []
        for item in items {
            views.append(toCareGapPolicyView(item))
        }
        return views
    }

    static func sumCareGapPolicyView(_ view: CareGapPolicyView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
