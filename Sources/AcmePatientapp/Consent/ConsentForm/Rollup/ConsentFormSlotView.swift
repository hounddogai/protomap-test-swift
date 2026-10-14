import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form slot.
    final class ConsentFormSlotView {
        var codeText: String
        var name: String
        var dosageMg: String
        var checksum: String
        var payerText: String
        var statusLabel: String

        init(codeText: String, name: String, dosageMg: String, checksum: String, payerText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.dosageMg = dosageMg
            self.checksum = checksum
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormSlotView(_ item: ConsentFormSlot) -> ConsentFormSlotView {
        return ConsentFormSlotView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            checksum: item.checksum,
            payerText: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormSlotViews(_ items: [ConsentFormSlot]) -> [ConsentFormSlotView] {
        var views: [ConsentFormSlotView] = []
        for item in items {
            views.append(toConsentFormSlotView(item))
        }
        return views
    }

    static func sumConsentFormSlotView(_ view: ConsentFormSlotView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
