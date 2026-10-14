import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality override.
    final class ModalityOverrideView {
        var code: String
        var name: String
        var revisionText: String
        var limit: String
        var active: String
        var phone: String
        var version: String
        var label: String
        var windowDaysText: String
        var visible: String
        var statusLabel: String

        init(code: String, name: String, revisionText: String, limit: String, active: String, phone: String, version: String, label: String, windowDaysText: String, visible: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revisionText = revisionText
            self.limit = limit
            self.active = active
            self.phone = phone
            self.version = version
            self.label = label
            self.windowDaysText = windowDaysText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toModalityOverrideView(_ item: ModalityOverride) -> ModalityOverrideView {
        return ModalityOverrideView(
            code: item.code,
            name: item.name,
            revisionText: String(item.revision),
            limit: String(item.limit),
            active: "\(item.active)",
            phone: Kit.Text.truncate(item.phone, limit: 64),
            version: String(item.version),
            label: Kit.Text.truncate(item.label, limit: 40),
            windowDaysText: String(item.windowDays),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityOverrideViews(_ items: [ModalityOverride]) -> [ModalityOverrideView] {
        var views: [ModalityOverrideView] = []
        for item in items {
            views.append(toModalityOverrideView(item))
        }
        return views
    }

    static func sumModalityOverrideView(_ view: ModalityOverrideView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRevision) + Double(parsedLimit) + Double(parsedVersion)
    }
}
