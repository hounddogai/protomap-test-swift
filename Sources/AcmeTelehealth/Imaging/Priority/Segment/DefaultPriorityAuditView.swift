import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default priority audit.
    final class DefaultPriorityAuditView {
        var code: String
        var name: String
        var ceiling: String
        var sourceText: String
        var locale: String
        var margin: String
        var version: String
        var countryText: String
        var phoneText: String
        var statusLabel: String

        init(code: String, name: String, ceiling: String, sourceText: String, locale: String, margin: String, version: String, countryText: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.sourceText = sourceText
            self.locale = locale
            self.margin = margin
            self.version = version
            self.countryText = countryText
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultPriorityAuditView(_ item: DefaultPriorityAudit) -> DefaultPriorityAuditView {
        return DefaultPriorityAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            sourceText: item.source,
            locale: item.locale,
            margin: String(format: "%.2f", item.margin),
            version: String(item.version),
            countryText: item.country,
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultPriorityAuditViews(_ items: [DefaultPriorityAudit]) -> [DefaultPriorityAuditView] {
        var views: [DefaultPriorityAuditView] = []
        for item in items {
            views.append(toDefaultPriorityAuditView(item))
        }
        return views
    }

    static func sumDefaultPriorityAuditView(_ view: DefaultPriorityAuditView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCeiling + parsedMargin + Double(parsedVersion)
    }
}
