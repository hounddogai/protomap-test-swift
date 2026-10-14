import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy formulary batch.
    final class LegacyFormularyBatchView {
        var codeText: String
        var nameText: String
        var revision: String
        var attempts: String
        var externalRef: String
        var clinicianID: String
        var source: String
        var statusLabel: String

        init(codeText: String, nameText: String, revision: String, attempts: String, externalRef: String, clinicianID: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.revision = revision
            self.attempts = attempts
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFormularyBatchView(_ item: LegacyFormularyBatch) -> LegacyFormularyBatchView {
        return LegacyFormularyBatchView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            revision: String(item.revision),
            attempts: String(item.attempts),
            externalRef: item.externalRef,
            clinicianID: item.clinicianID,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFormularyBatchViews(_ items: [LegacyFormularyBatch]) -> [LegacyFormularyBatchView] {
        var views: [LegacyFormularyBatchView] = []
        for item in items {
            views.append(toLegacyFormularyBatchView(item))
        }
        return views
    }

    static func sumLegacyFormularyBatchView(_ view: LegacyFormularyBatchView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRevision) + Double(parsedAttempts)
    }
}
