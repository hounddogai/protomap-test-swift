import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read target.
    final class ReadTargetView {
        var code: String
        var label: String
        var copayText: String
        var ownerID: String
        var visitMinutes: String
        var encounterID: String
        var pinned: String
        var limitText: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, label: String, copayText: String, ownerID: String, visitMinutes: String, encounterID: String, pinned: String, limitText: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copayText = copayText
            self.ownerID = ownerID
            self.visitMinutes = visitMinutes
            self.encounterID = encounterID
            self.pinned = pinned
            self.limitText = limitText
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toReadTargetView(_ item: ReadTarget) -> ReadTargetView {
        return ReadTargetView(
            code: item.code,
            label: item.label,
            copayText: String(format: "%.2f", item.copay),
            ownerID: item.ownerID,
            visitMinutes: String(item.visitMinutes),
            encounterID: item.encounterID,
            pinned: "\(item.pinned)",
            limitText: String(item.limit),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadTargetViews(_ items: [ReadTarget]) -> [ReadTargetView] {
        var views: [ReadTargetView] = []
        for item in items {
            views.append(toReadTargetView(item))
        }
        return views
    }

    static func sumReadTargetView(_ view: ReadTargetView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCopay + Double(parsedVisitMinutes) + Double(parsedLimit)
    }
}
