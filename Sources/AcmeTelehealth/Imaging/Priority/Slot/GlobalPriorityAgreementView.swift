import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global priority agreement.
    final class GlobalPriorityAgreementView {
        var code: String
        var name: String
        var versionText: String
        var ownerID: String
        var maximumText: String
        var statusLabel: String

        init(code: String, name: String, versionText: String, ownerID: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.versionText = versionText
            self.ownerID = ownerID
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalPriorityAgreementView(_ item: GlobalPriorityAgreement) -> GlobalPriorityAgreementView {
        return GlobalPriorityAgreementView(
            code: item.code,
            name: item.name,
            versionText: String(item.version),
            ownerID: item.ownerID,
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalPriorityAgreementViews(_ items: [GlobalPriorityAgreement]) -> [GlobalPriorityAgreementView] {
        var views: [GlobalPriorityAgreementView] = []
        for item in items {
            views.append(toGlobalPriorityAgreementView(item))
        }
        return views
    }

    static func sumGlobalPriorityAgreementView(_ view: GlobalPriorityAgreementView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedVersion) + parsedMaximum
    }
}
