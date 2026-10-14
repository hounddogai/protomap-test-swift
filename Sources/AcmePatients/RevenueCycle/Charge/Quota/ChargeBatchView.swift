import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge batch.
    final class ChargeBatchView {
        var code: String
        var name: String
        var segment: String
        var phoneText: String
        var clinicianIDText: String
        var externalRefText: String
        var channel: String
        var bed: String
        var copay: String
        var procedureCodeText: String
        var sequence: String
        var statusLabel: String

        init(code: String, name: String, segment: String, phoneText: String, clinicianIDText: String, externalRefText: String, channel: String, bed: String, copay: String, procedureCodeText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segment = segment
            self.phoneText = phoneText
            self.clinicianIDText = clinicianIDText
            self.externalRefText = externalRefText
            self.channel = channel
            self.bed = bed
            self.copay = copay
            self.procedureCodeText = procedureCodeText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toChargeBatchView(_ item: ChargeBatch) -> ChargeBatchView {
        return ChargeBatchView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            phoneText: item.phone,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 120),
            channel: item.channel,
            bed: Kit.Text.truncate(item.bed, limit: 40),
            copay: String(format: "%.2f", item.copay),
            procedureCodeText: item.procedureCode,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeBatchViews(_ items: [ChargeBatch]) -> [ChargeBatchView] {
        var views: [ChargeBatchView] = []
        for item in items {
            views.append(toChargeBatchView(item))
        }
        return views
    }

    static func sumChargeBatchView(_ view: ChargeBatchView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedCopay + Double(parsedSequence)
    }
}
