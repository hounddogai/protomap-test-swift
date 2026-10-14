import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default consent form cycle.
    final class DefaultConsentFormCycleView {
        var codeText: String
        var title: String
        var wardText: String
        var copay: String
        var patientRef: String
        var dosageMgText: String
        var pinned: String
        var quantityText: String
        var channel: String
        var statusLabel: String

        init(codeText: String, title: String, wardText: String, copay: String, patientRef: String, dosageMgText: String, pinned: String, quantityText: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.wardText = wardText
            self.copay = copay
            self.patientRef = patientRef
            self.dosageMgText = dosageMgText
            self.pinned = pinned
            self.quantityText = quantityText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultConsentFormCycleView(_ item: DefaultConsentFormCycle) -> DefaultConsentFormCycleView {
        return DefaultConsentFormCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            wardText: Kit.Text.truncate(item.ward, limit: 40),
            copay: String(format: "%.2f", item.copay),
            patientRef: item.patientRef,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            pinned: "\(item.pinned)",
            quantityText: String(item.quantity),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultConsentFormCycleViews(_ items: [DefaultConsentFormCycle]) -> [DefaultConsentFormCycleView] {
        var views: [DefaultConsentFormCycleView] = []
        for item in items {
            views.append(toDefaultConsentFormCycleView(item))
        }
        return views
    }

    static func sumDefaultConsentFormCycleView(_ view: DefaultConsentFormCycleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCopay + parsedDosageMg + Double(parsedQuantity)
    }
}
