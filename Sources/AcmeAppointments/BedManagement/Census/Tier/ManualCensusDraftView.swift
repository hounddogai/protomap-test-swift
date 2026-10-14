import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual census draft.
    final class ManualCensusDraftView {
        var code: String
        var label: String
        var notesText: String
        var encounterID: String
        var description: String
        var retriesText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, label: String, notesText: String, encounterID: String, description: String, retriesText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.notesText = notesText
            self.encounterID = encounterID
            self.description = description
            self.retriesText = retriesText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toManualCensusDraftView(_ item: ManualCensusDraft) -> ManualCensusDraftView {
        return ManualCensusDraftView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 120),
            notesText: item.notes,
            encounterID: item.encounterID,
            description: Kit.Text.truncate(item.description, limit: 80),
            retriesText: String(item.retries),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCensusDraftViews(_ items: [ManualCensusDraft]) -> [ManualCensusDraftView] {
        var views: [ManualCensusDraftView] = []
        for item in items {
            views.append(toManualCensusDraftView(item))
        }
        return views
    }

    static func sumManualCensusDraftView(_ view: ManualCensusDraftView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
