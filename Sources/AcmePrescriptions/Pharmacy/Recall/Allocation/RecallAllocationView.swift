import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall allocation.
    final class RecallAllocationView {
        var codeText: String
        var title: String
        var revision: String
        var durationMinutesText: String
        var active: String
        var limit: String
        var visitMinutes: String
        var source: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, title: String, revision: String, durationMinutesText: String, active: String, limit: String, visitMinutes: String, source: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.revision = revision
            self.durationMinutesText = durationMinutesText
            self.active = active
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.source = source
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toRecallAllocationView(_ item: RecallAllocation) -> RecallAllocationView {
        return RecallAllocationView(
            codeText: item.code,
            title: item.title,
            revision: String(item.revision),
            durationMinutesText: String(item.durationMinutes),
            active: "\(item.active)",
            limit: String(item.limit),
            visitMinutes: String(item.visitMinutes),
            source: Kit.Text.truncate(item.source, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallAllocationViews(_ items: [RecallAllocation]) -> [RecallAllocationView] {
        var views: [RecallAllocationView] = []
        for item in items {
            views.append(toRecallAllocationView(item))
        }
        return views
    }

    static func sumRecallAllocationView(_ view: RecallAllocationView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRevision) + Double(parsedDurationMinutes) + Double(parsedLimit)
    }
}
