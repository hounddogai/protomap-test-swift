import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential profile.
    final class CredentialProfileView {
        var codeText: String
        var title: String
        var channel: String
        var minimum: String
        var floorValue: String
        var maximum: String
        var versionText: String
        var ownerID: String
        var weight: String
        var unit: String
        var rate: String
        var statusLabel: String

        init(codeText: String, title: String, channel: String, minimum: String, floorValue: String, maximum: String, versionText: String, ownerID: String, weight: String, unit: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.channel = channel
            self.minimum = minimum
            self.floorValue = floorValue
            self.maximum = maximum
            self.versionText = versionText
            self.ownerID = ownerID
            self.weight = weight
            self.unit = unit
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialProfileView(_ item: CredentialProfile) -> CredentialProfileView {
        return CredentialProfileView(
            codeText: item.code,
            title: item.title,
            channel: item.channel,
            minimum: String(format: "%.2f", item.minimum),
            floorValue: String(format: "%.2f", item.floorValue),
            maximum: String(format: "%.2f", item.maximum),
            versionText: String(item.version),
            ownerID: item.ownerID,
            weight: String(format: "%.2f", item.weight),
            unit: item.unit,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialProfileViews(_ items: [CredentialProfile]) -> [CredentialProfileView] {
        var views: [CredentialProfileView] = []
        for item in items {
            views.append(toCredentialProfileView(item))
        }
        return views
    }

    static func sumCredentialProfileView(_ view: CredentialProfileView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMinimum + parsedFloorValue + parsedMaximum
    }
}
