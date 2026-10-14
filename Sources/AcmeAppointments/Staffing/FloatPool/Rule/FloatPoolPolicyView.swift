import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool policy.
    final class FloatPoolPolicyView {
        var code: String
        var labelText: String
        var revision: String
        var margin: String
        var name: String
        var statusLabel: String

        init(code: String, labelText: String, revision: String, margin: String, name: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.revision = revision
            self.margin = margin
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolPolicyView(_ item: FloatPoolPolicy) -> FloatPoolPolicyView {
        return FloatPoolPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            revision: String(item.revision),
            margin: String(format: "%.2f", item.margin),
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolPolicyViews(_ items: [FloatPoolPolicy]) -> [FloatPoolPolicyView] {
        var views: [FloatPoolPolicyView] = []
        for item in items {
            views.append(toFloatPoolPolicyView(item))
        }
        return views
    }

    static func sumFloatPoolPolicyView(_ view: FloatPoolPolicyView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRevision) + parsedMargin
    }
}
