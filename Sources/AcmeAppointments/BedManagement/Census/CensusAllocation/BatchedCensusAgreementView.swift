import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched census agreement.
    final class BatchedCensusAgreementView {
        var code: String
        var nameText: String
        var procedureCode: String
        var facility: String
        var specialty: String
        var pinned: String
        var payerText: String
        var dosageMg: String
        var phoneText: String
        var statusLabel: String

        init(code: String, nameText: String, procedureCode: String, facility: String, specialty: String, pinned: String, payerText: String, dosageMg: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.procedureCode = procedureCode
            self.facility = facility
            self.specialty = specialty
            self.pinned = pinned
            self.payerText = payerText
            self.dosageMg = dosageMg
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCensusAgreementView(_ item: BatchedCensusAgreement) -> BatchedCensusAgreementView {
        return BatchedCensusAgreementView(
            code: item.code,
            nameText: item.name,
            procedureCode: item.procedureCode,
            facility: item.facility,
            specialty: item.specialty,
            pinned: "\(item.pinned)",
            payerText: Kit.Text.truncate(item.payer, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCensusAgreementViews(_ items: [BatchedCensusAgreement]) -> [BatchedCensusAgreementView] {
        var views: [BatchedCensusAgreementView] = []
        for item in items {
            views.append(toBatchedCensusAgreementView(item))
        }
        return views
    }

    static func sumBatchedCensusAgreementView(_ view: BatchedCensusAgreementView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
