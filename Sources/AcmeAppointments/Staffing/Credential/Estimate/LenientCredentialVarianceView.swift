import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient credential variance.
    final class LenientCredentialVarianceView {
        var code: String
        var label: String
        var threshold: String
        var ward: String
        var category: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, ward: String, category: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.ward = ward
            self.category = category
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCredentialVarianceView(_ item: LenientCredentialVariance) -> LenientCredentialVarianceView {
        return LenientCredentialVarianceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            ward: item.ward,
            category: item.category,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCredentialVarianceViews(_ items: [LenientCredentialVariance]) -> [LenientCredentialVarianceView] {
        var views: [LenientCredentialVarianceView] = []
        for item in items {
            views.append(toLenientCredentialVarianceView(item))
        }
        return views
    }

    static func sumLenientCredentialVarianceView(_ view: LenientCredentialVarianceView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedThreshold + Double(parsedPriority)
    }
}
