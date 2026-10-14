import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim digest.
    final class ClaimDigestView {
        var codeText: String
        var label: String
        var dosageMgText: String
        var procedureCode: String
        var margin: String
        var notesText: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMgText: String, procedureCode: String, margin: String, notesText: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMgText = dosageMgText
            self.procedureCode = procedureCode
            self.margin = margin
            self.notesText = notesText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toClaimDigestView(_ item: ClaimDigest) -> ClaimDigestView {
        return ClaimDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 40),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            procedureCode: item.procedureCode,
            margin: String(format: "%.2f", item.margin),
            notesText: Kit.Text.truncate(item.notes, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimDigestViews(_ items: [ClaimDigest]) -> [ClaimDigestView] {
        var views: [ClaimDigestView] = []
        for item in items {
            views.append(toClaimDigestView(item))
        }
        return views
    }

    static func sumClaimDigestView(_ view: ClaimDigestView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedDosageMg + parsedMargin + parsedMaximum
    }
}
