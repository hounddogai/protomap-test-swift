import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form adjustment.
    final class ConsentFormAdjustmentView {
        var code: String
        var titleText: String
        var version: String
        var minimum: String
        var limitText: String
        var clinicianID: String
        var phoneText: String
        var statusLabel: String

        init(code: String, titleText: String, version: String, minimum: String, limitText: String, clinicianID: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.version = version
            self.minimum = minimum
            self.limitText = limitText
            self.clinicianID = clinicianID
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormAdjustmentView(_ item: ConsentFormAdjustment) -> ConsentFormAdjustmentView {
        return ConsentFormAdjustmentView(
            code: item.code,
            titleText: item.title,
            version: String(item.version),
            minimum: String(format: "%.2f", item.minimum),
            limitText: String(item.limit),
            clinicianID: item.clinicianID,
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormAdjustmentViews(_ items: [ConsentFormAdjustment]) -> [ConsentFormAdjustmentView] {
        var views: [ConsentFormAdjustmentView] = []
        for item in items {
            views.append(toConsentFormAdjustmentView(item))
        }
        return views
    }

    static func sumConsentFormAdjustmentView(_ view: ConsentFormAdjustmentView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedVersion) + parsedMinimum + Double(parsedLimit)
    }
}
