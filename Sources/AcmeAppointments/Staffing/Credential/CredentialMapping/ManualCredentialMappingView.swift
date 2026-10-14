import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual credential mapping.
    final class ManualCredentialMappingView {
        var code: String
        var nameText: String
        var durationMinutesText: String
        var archived: String
        var source: String
        var activeText: String
        var timezone: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, nameText: String, durationMinutesText: String, archived: String, source: String, activeText: String, timezone: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.durationMinutesText = durationMinutesText
            self.archived = archived
            self.source = source
            self.activeText = activeText
            self.timezone = timezone
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCredentialMappingView(_ item: ManualCredentialMapping) -> ManualCredentialMappingView {
        return ManualCredentialMappingView(
            code: item.code,
            nameText: item.name,
            durationMinutesText: String(item.durationMinutes),
            archived: "\(item.archived)",
            source: item.source,
            activeText: "\(item.active)",
            timezone: item.timezone,
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCredentialMappingViews(_ items: [ManualCredentialMapping]) -> [ManualCredentialMappingView] {
        var views: [ManualCredentialMappingView] = []
        for item in items {
            views.append(toManualCredentialMappingView(item))
        }
        return views
    }

    static func sumManualCredentialMappingView(_ view: ManualCredentialMappingView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedDurationMinutes) + parsedThreshold
    }
}
