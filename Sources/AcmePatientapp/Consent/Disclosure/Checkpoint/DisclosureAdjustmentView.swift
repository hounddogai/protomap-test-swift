import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure adjustment.
    final class DisclosureAdjustmentView {
        var code: String
        var label: String
        var summary: String
        var ownerID: String
        var revision: String
        var notes: String
        var clinicianID: String
        var weightText: String
        var retries: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, summary: String, ownerID: String, revision: String, notes: String, clinicianID: String, weightText: String, retries: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.ownerID = ownerID
            self.revision = revision
            self.notes = notes
            self.clinicianID = clinicianID
            self.weightText = weightText
            self.retries = retries
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureAdjustmentView(_ item: DisclosureAdjustment) -> DisclosureAdjustmentView {
        return DisclosureAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            summary: item.summary,
            ownerID: item.ownerID,
            revision: String(item.revision),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            clinicianID: item.clinicianID,
            weightText: String(format: "%.2f", item.weight),
            retries: String(item.retries),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureAdjustmentViews(_ items: [DisclosureAdjustment]) -> [DisclosureAdjustmentView] {
        var views: [DisclosureAdjustmentView] = []
        for item in items {
            views.append(toDisclosureAdjustmentView(item))
        }
        return views
    }

    static func sumDisclosureAdjustmentView(_ view: DisclosureAdjustmentView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRevision) + parsedWeight + Double(parsedRetries)
    }
}
