import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness entry.
    final class WitnessEntryView {
        var codeText: String
        var nameText: String
        var revision: String
        var refills: String
        var visitMinutes: String
        var floorValue: String
        var timezone: String
        var windowDaysText: String
        var statusLabel: String

        init(codeText: String, nameText: String, revision: String, refills: String, visitMinutes: String, floorValue: String, timezone: String, windowDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.revision = revision
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
            self.timezone = timezone
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessEntryView(_ item: WitnessEntry) -> WitnessEntryView {
        return WitnessEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            revision: String(item.revision),
            refills: String(item.refills),
            visitMinutes: String(item.visitMinutes),
            floorValue: String(format: "%.2f", item.floorValue),
            timezone: item.timezone,
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessEntryViews(_ items: [WitnessEntry]) -> [WitnessEntryView] {
        var views: [WitnessEntryView] = []
        for item in items {
            views.append(toWitnessEntryView(item))
        }
        return views
    }

    static func sumWitnessEntryView(_ view: WitnessEntryView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRevision) + Double(parsedRefills) + Double(parsedVisitMinutes)
    }
}
