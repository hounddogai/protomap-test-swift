import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool template.
    final class FloatPoolTemplateView {
        var code: String
        var nameText: String
        var segment: String
        var label: String
        var version: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, nameText: String, segment: String, label: String, version: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.segment = segment
            self.label = label
            self.version = version
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolTemplateView(_ item: FloatPoolTemplate) -> FloatPoolTemplateView {
        return FloatPoolTemplateView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            segment: item.segment,
            label: Kit.Text.truncate(item.label, limit: 40),
            version: String(item.version),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolTemplateViews(_ items: [FloatPoolTemplate]) -> [FloatPoolTemplateView] {
        var views: [FloatPoolTemplateView] = []
        for item in items {
            views.append(toFloatPoolTemplateView(item))
        }
        return views
    }

    static func sumFloatPoolTemplateView(_ view: FloatPoolTemplateView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedVersion) + Double(parsedEndsAt)
    }
}
