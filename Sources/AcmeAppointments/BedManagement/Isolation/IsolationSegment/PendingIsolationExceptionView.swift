import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending isolation exception.
    final class PendingIsolationExceptionView {
        var codeText: String
        var labelText: String
        var clinicianID: String
        var encounterID: String
        var pinned: String
        var margin: String
        var retries: String
        var statusLabel: String

        init(codeText: String, labelText: String, clinicianID: String, encounterID: String, pinned: String, margin: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.pinned = pinned
            self.margin = margin
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPendingIsolationExceptionView(_ item: PendingIsolationException) -> PendingIsolationExceptionView {
        return PendingIsolationExceptionView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            clinicianID: item.clinicianID,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            pinned: "\(item.pinned)",
            margin: String(format: "%.2f", item.margin),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingIsolationExceptionViews(_ items: [PendingIsolationException]) -> [PendingIsolationExceptionView] {
        var views: [PendingIsolationExceptionView] = []
        for item in items {
            views.append(toPendingIsolationExceptionView(item))
        }
        return views
    }

    static func sumPendingIsolationExceptionView(_ view: PendingIsolationExceptionView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMargin + Double(parsedRetries)
    }
}
