import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual transfer template.
    final class ManualTransferTemplateView {
        var codeText: String
        var titleText: String
        var reviewer: String
        var maximumText: String
        var priority: String
        var copay: String
        var attempts: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, titleText: String, reviewer: String, maximumText: String, priority: String, copay: String, attempts: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.reviewer = reviewer
            self.maximumText = maximumText
            self.priority = priority
            self.copay = copay
            self.attempts = attempts
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toManualTransferTemplateView(_ item: ManualTransferTemplate) -> ManualTransferTemplateView {
        return ManualTransferTemplateView(
            codeText: item.code,
            titleText: item.title,
            reviewer: item.reviewer,
            maximumText: String(format: "%.2f", item.maximum),
            priority: String(item.priority),
            copay: String(format: "%.2f", item.copay),
            attempts: String(item.attempts),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualTransferTemplateViews(_ items: [ManualTransferTemplate]) -> [ManualTransferTemplateView] {
        var views: [ManualTransferTemplateView] = []
        for item in items {
            views.append(toManualTransferTemplateView(item))
        }
        return views
    }

    static func sumManualTransferTemplateView(_ view: ManualTransferTemplateView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMaximum + Double(parsedPriority) + parsedCopay
    }
}
