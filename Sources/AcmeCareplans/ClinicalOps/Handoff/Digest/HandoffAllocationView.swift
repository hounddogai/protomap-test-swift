import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff allocation.
    final class HandoffAllocationView {
        var code: String
        var titleText: String
        var label: String
        var copay: String
        var attempts: String
        var visitMinutesText: String
        var maximum: String
        var statusLabel: String

        init(code: String, titleText: String, label: String, copay: String, attempts: String, visitMinutesText: String, maximum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.label = label
            self.copay = copay
            self.attempts = attempts
            self.visitMinutesText = visitMinutesText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffAllocationView(_ item: HandoffAllocation) -> HandoffAllocationView {
        return HandoffAllocationView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            attempts: String(item.attempts),
            visitMinutesText: String(item.visitMinutes),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffAllocationViews(_ items: [HandoffAllocation]) -> [HandoffAllocationView] {
        var views: [HandoffAllocationView] = []
        for item in items {
            views.append(toHandoffAllocationView(item))
        }
        return views
    }

    static func sumHandoffAllocationView(_ view: HandoffAllocationView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedCopay + Double(parsedAttempts) + Double(parsedVisitMinutes)
    }
}
