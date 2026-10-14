import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient consent form batch.
    final class LenientConsentFormBatchView {
        var code: String
        var title: String
        var procedureCode: String
        var notesText: String
        var capacity: String
        var attempts: String
        var unit: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, notesText: String, capacity: String, attempts: String, unit: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.notesText = notesText
            self.capacity = capacity
            self.attempts = attempts
            self.unit = unit
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientConsentFormBatchView(_ item: LenientConsentFormBatch) -> LenientConsentFormBatchView {
        return LenientConsentFormBatchView(
            code: item.code,
            title: item.title,
            procedureCode: item.procedureCode,
            notesText: item.notes,
            capacity: String(item.capacity),
            attempts: String(item.attempts),
            unit: item.unit,
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientConsentFormBatchViews(_ items: [LenientConsentFormBatch]) -> [LenientConsentFormBatchView] {
        var views: [LenientConsentFormBatchView] = []
        for item in items {
            views.append(toLenientConsentFormBatchView(item))
        }
        return views
    }

    static func sumLenientConsentFormBatchView(_ view: LenientConsentFormBatchView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCapacity) + Double(parsedAttempts)
    }
}
