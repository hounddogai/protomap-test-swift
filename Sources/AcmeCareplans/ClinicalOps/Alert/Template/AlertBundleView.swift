import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert bundle.
    final class AlertBundleView {
        var codeText: String
        var labelText: String
        var windowDays: String
        var quantity: String
        var durationMinutes: String
        var notes: String
        var allergyText: String
        var minimum: String
        var batchSizeText: String
        var activeText: String
        var score: String
        var statusLabel: String

        init(codeText: String, labelText: String, windowDays: String, quantity: String, durationMinutes: String, notes: String, allergyText: String, minimum: String, batchSizeText: String, activeText: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.windowDays = windowDays
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.notes = notes
            self.allergyText = allergyText
            self.minimum = minimum
            self.batchSizeText = batchSizeText
            self.activeText = activeText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toAlertBundleView(_ item: AlertBundle) -> AlertBundleView {
        return AlertBundleView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            windowDays: String(item.windowDays),
            quantity: String(item.quantity),
            durationMinutes: String(item.durationMinutes),
            notes: item.notes,
            allergyText: item.allergy,
            minimum: String(format: "%.2f", item.minimum),
            batchSizeText: String(item.batchSize),
            activeText: "\(item.active)",
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertBundleViews(_ items: [AlertBundle]) -> [AlertBundleView] {
        var views: [AlertBundleView] = []
        for item in items {
            views.append(toAlertBundleView(item))
        }
        return views
    }

    static func sumAlertBundleView(_ view: AlertBundleView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedQuantity) + Double(parsedDurationMinutes)
    }
}
