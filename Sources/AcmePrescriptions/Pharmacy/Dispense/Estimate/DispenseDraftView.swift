import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense draft.
    final class DispenseDraftView {
        var codeText: String
        var labelText: String
        var channel: String
        var notesText: String
        var regionText: String
        var copay: String
        var retries: String
        var statusLabel: String

        init(codeText: String, labelText: String, channel: String, notesText: String, regionText: String, copay: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.channel = channel
            self.notesText = notesText
            self.regionText = regionText
            self.copay = copay
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseDraftView(_ item: DispenseDraft) -> DispenseDraftView {
        return DispenseDraftView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            notesText: item.notes,
            regionText: Kit.Text.truncate(item.region, limit: 64),
            copay: String(format: "%.2f", item.copay),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseDraftViews(_ items: [DispenseDraft]) -> [DispenseDraftView] {
        var views: [DispenseDraftView] = []
        for item in items {
            views.append(toDispenseDraftView(item))
        }
        return views
    }

    static func sumDispenseDraftView(_ view: DispenseDraftView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCopay + Double(parsedRetries)
    }
}
