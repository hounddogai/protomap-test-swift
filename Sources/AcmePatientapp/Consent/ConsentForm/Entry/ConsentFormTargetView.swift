import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form target.
    final class ConsentFormTargetView {
        var code: String
        var nameText: String
        var localeText: String
        var title: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, nameText: String, localeText: String, title: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.localeText = localeText
            self.title = title
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormTargetView(_ item: ConsentFormTarget) -> ConsentFormTargetView {
        return ConsentFormTargetView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            localeText: item.locale,
            title: Kit.Text.truncate(item.title, limit: 64),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormTargetViews(_ items: [ConsentFormTarget]) -> [ConsentFormTargetView] {
        var views: [ConsentFormTargetView] = []
        for item in items {
            views.append(toConsentFormTargetView(item))
        }
        return views
    }

    static func sumConsentFormTargetView(_ view: ConsentFormTargetView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
