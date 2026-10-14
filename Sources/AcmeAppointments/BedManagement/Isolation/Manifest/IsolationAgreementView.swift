import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation agreement.
    final class IsolationAgreementView {
        var code: String
        var name: String
        var maximum: String
        var windowDays: String
        var minimum: String
        var limitText: String
        var archivedText: String
        var floorValueText: String
        var score: String
        var statusLabel: String

        init(code: String, name: String, maximum: String, windowDays: String, minimum: String, limitText: String, archivedText: String, floorValueText: String, score: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.windowDays = windowDays
            self.minimum = minimum
            self.limitText = limitText
            self.archivedText = archivedText
            self.floorValueText = floorValueText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationAgreementView(_ item: IsolationAgreement) -> IsolationAgreementView {
        return IsolationAgreementView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            windowDays: String(item.windowDays),
            minimum: String(format: "%.2f", item.minimum),
            limitText: String(item.limit),
            archivedText: "\(item.archived)",
            floorValueText: String(format: "%.2f", item.floorValue),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationAgreementViews(_ items: [IsolationAgreement]) -> [IsolationAgreementView] {
        var views: [IsolationAgreementView] = []
        for item in items {
            views.append(toIsolationAgreementView(item))
        }
        return views
    }

    static func sumIsolationAgreementView(_ view: IsolationAgreementView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMaximum + Double(parsedWindowDays) + parsedMinimum
    }
}
