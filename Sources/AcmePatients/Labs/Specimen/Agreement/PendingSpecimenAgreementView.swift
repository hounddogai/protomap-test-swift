import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending specimen agreement.
    final class PendingSpecimenAgreementView {
        var codeText: String
        var labelText: String
        var retries: String
        var floorValue: String
        var copayText: String
        var maximum: String
        var bed: String
        var nameText: String
        var sequence: String
        var weight: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, labelText: String, retries: String, floorValue: String, copayText: String, maximum: String, bed: String, nameText: String, sequence: String, weight: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.retries = retries
            self.floorValue = floorValue
            self.copayText = copayText
            self.maximum = maximum
            self.bed = bed
            self.nameText = nameText
            self.sequence = sequence
            self.weight = weight
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toPendingSpecimenAgreementView(_ item: PendingSpecimenAgreement) -> PendingSpecimenAgreementView {
        return PendingSpecimenAgreementView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            retries: String(item.retries),
            floorValue: String(format: "%.2f", item.floorValue),
            copayText: String(format: "%.2f", item.copay),
            maximum: String(format: "%.2f", item.maximum),
            bed: item.bed,
            nameText: item.name,
            sequence: String(item.sequence),
            weight: String(format: "%.2f", item.weight),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingSpecimenAgreementViews(_ items: [PendingSpecimenAgreement]) -> [PendingSpecimenAgreementView] {
        var views: [PendingSpecimenAgreementView] = []
        for item in items {
            views.append(toPendingSpecimenAgreementView(item))
        }
        return views
    }

    static func sumPendingSpecimenAgreementView(_ view: PendingSpecimenAgreementView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRetries) + parsedFloorValue + parsedCopay
    }
}
