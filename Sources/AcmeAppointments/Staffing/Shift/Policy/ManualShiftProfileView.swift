import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual shift profile.
    final class ManualShiftProfileView {
        var codeText: String
        var label: String
        var retries: String
        var externalRef: String
        var discount: String
        var statusLabel: String

        init(codeText: String, label: String, retries: String, externalRef: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.retries = retries
            self.externalRef = externalRef
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toManualShiftProfileView(_ item: ManualShiftProfile) -> ManualShiftProfileView {
        return ManualShiftProfileView(
            codeText: item.code,
            label: item.label,
            retries: String(item.retries),
            externalRef: item.externalRef,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualShiftProfileViews(_ items: [ManualShiftProfile]) -> [ManualShiftProfileView] {
        var views: [ManualShiftProfileView] = []
        for item in items {
            views.append(toManualShiftProfileView(item))
        }
        return views
    }

    static func sumManualShiftProfileView(_ view: ManualShiftProfileView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRetries) + parsedDiscount
    }
}
