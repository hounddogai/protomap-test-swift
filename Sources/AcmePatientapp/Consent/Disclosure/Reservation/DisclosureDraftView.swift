import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure draft.
    final class DisclosureDraftView {
        var code: String
        var labelText: String
        var segmentText: String
        var wardText: String
        var clinicianID: String
        var copay: String
        var statusLabel: String

        init(code: String, labelText: String, segmentText: String, wardText: String, clinicianID: String, copay: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.segmentText = segmentText
            self.wardText = wardText
            self.clinicianID = clinicianID
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureDraftView(_ item: DisclosureDraft) -> DisclosureDraftView {
        return DisclosureDraftView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            segmentText: item.segment,
            wardText: item.ward,
            clinicianID: item.clinicianID,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureDraftViews(_ items: [DisclosureDraft]) -> [DisclosureDraftView] {
        var views: [DisclosureDraftView] = []
        for item in items {
            views.append(toDisclosureDraftView(item))
        }
        return views
    }

    static func sumDisclosureDraftView(_ view: DisclosureDraftView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
