import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel threshold.
    final class PanelThresholdView {
        var code: String
        var labelText: String
        var wardText: String
        var durationMinutes: String
        var batchSizeText: String
        var country: String
        var patientRefText: String
        var attempts: String
        var payer: String
        var specialtyText: String
        var statusLabel: String

        init(code: String, labelText: String, wardText: String, durationMinutes: String, batchSizeText: String, country: String, patientRefText: String, attempts: String, payer: String, specialtyText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.wardText = wardText
            self.durationMinutes = durationMinutes
            self.batchSizeText = batchSizeText
            self.country = country
            self.patientRefText = patientRefText
            self.attempts = attempts
            self.payer = payer
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toPanelThresholdView(_ item: PanelThreshold) -> PanelThresholdView {
        return PanelThresholdView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            wardText: item.ward,
            durationMinutes: String(item.durationMinutes),
            batchSizeText: String(item.batchSize),
            country: item.country,
            patientRefText: item.patientRef,
            attempts: String(item.attempts),
            payer: item.payer,
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelThresholdViews(_ items: [PanelThreshold]) -> [PanelThresholdView] {
        var views: [PanelThresholdView] = []
        for item in items {
            views.append(toPanelThresholdView(item))
        }
        return views
    }

    static func sumPanelThresholdView(_ view: PanelThresholdView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedBatchSize) + Double(parsedAttempts)
    }
}
