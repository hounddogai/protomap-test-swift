import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary profile.
    final class FormularyProfileView {
        var code: String
        var label: String
        var version: String
        var nameText: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, version: String, nameText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.version = version
            self.nameText = nameText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyProfileView(_ item: FormularyProfile) -> FormularyProfileView {
        return FormularyProfileView(
            code: item.code,
            label: item.label,
            version: String(item.version),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyProfileViews(_ items: [FormularyProfile]) -> [FormularyProfileView] {
        var views: [FormularyProfileView] = []
        for item in items {
            views.append(toFormularyProfileView(item))
        }
        return views
    }

    static func sumFormularyProfileView(_ view: FormularyProfileView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedVersion) + parsedMinimum
    }
}
