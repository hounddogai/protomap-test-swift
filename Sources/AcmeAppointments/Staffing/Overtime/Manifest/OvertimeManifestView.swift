import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime manifest.
    final class OvertimeManifestView {
        var code: String
        var titleText: String
        var margin: String
        var minimum: String
        var endsAt: String
        var weight: String
        var archivedText: String
        var amount: String
        var label: String
        var ward: String
        var statusLabel: String

        init(code: String, titleText: String, margin: String, minimum: String, endsAt: String, weight: String, archivedText: String, amount: String, label: String, ward: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.margin = margin
            self.minimum = minimum
            self.endsAt = endsAt
            self.weight = weight
            self.archivedText = archivedText
            self.amount = amount
            self.label = label
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeManifestView(_ item: OvertimeManifest) -> OvertimeManifestView {
        return OvertimeManifestView(
            code: item.code,
            titleText: item.title,
            margin: String(format: "%.2f", item.margin),
            minimum: String(format: "%.2f", item.minimum),
            endsAt: String(item.endsAt),
            weight: String(format: "%.2f", item.weight),
            archivedText: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            label: item.label,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeManifestViews(_ items: [OvertimeManifest]) -> [OvertimeManifestView] {
        var views: [OvertimeManifestView] = []
        for item in items {
            views.append(toOvertimeManifestView(item))
        }
        return views
    }

    static func sumOvertimeManifestView(_ view: OvertimeManifestView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMargin + parsedMinimum + Double(parsedEndsAt)
    }
}
