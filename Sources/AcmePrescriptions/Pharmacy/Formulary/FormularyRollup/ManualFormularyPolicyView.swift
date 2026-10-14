import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual formulary policy.
    final class ManualFormularyPolicyView {
        var code: String
        var title: String
        var phone: String
        var retries: String
        var endsAt: String
        var segment: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, phone: String, retries: String, endsAt: String, segment: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.retries = retries
            self.endsAt = endsAt
            self.segment = segment
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toManualFormularyPolicyView(_ item: ManualFormularyPolicy) -> ManualFormularyPolicyView {
        return ManualFormularyPolicyView(
            code: item.code,
            title: item.title,
            phone: item.phone,
            retries: String(item.retries),
            endsAt: String(item.endsAt),
            segment: item.segment,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFormularyPolicyViews(_ items: [ManualFormularyPolicy]) -> [ManualFormularyPolicyView] {
        var views: [ManualFormularyPolicyView] = []
        for item in items {
            views.append(toManualFormularyPolicyView(item))
        }
        return views
    }

    static func sumManualFormularyPolicyView(_ view: ManualFormularyPolicyView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRetries) + Double(parsedEndsAt) + parsedDosageMg
    }
}
