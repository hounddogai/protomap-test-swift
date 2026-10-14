import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient rounding snapshot.
    final class LenientRoundingSnapshotView {
        var code: String
        var label: String
        var copay: String
        var notes: String
        var visible: String
        var payerText: String
        var score: String
        var wardText: String
        var currency: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, copay: String, notes: String, visible: String, payerText: String, score: String, wardText: String, currency: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copay = copay
            self.notes = notes
            self.visible = visible
            self.payerText = payerText
            self.score = score
            self.wardText = wardText
            self.currency = currency
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRoundingSnapshotView(_ item: LenientRoundingSnapshot) -> LenientRoundingSnapshotView {
        return LenientRoundingSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 80),
            copay: String(format: "%.2f", item.copay),
            notes: item.notes,
            visible: "\(item.visible)",
            payerText: item.payer,
            score: String(format: "%.2f", item.score),
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            currency: item.currency,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRoundingSnapshotViews(_ items: [LenientRoundingSnapshot]) -> [LenientRoundingSnapshotView] {
        var views: [LenientRoundingSnapshotView] = []
        for item in items {
            views.append(toLenientRoundingSnapshotView(item))
        }
        return views
    }

    static func sumLenientRoundingSnapshotView(_ view: LenientRoundingSnapshotView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCopay + parsedScore
    }
}
