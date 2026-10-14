import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense snapshot.
    final class DispenseSnapshotView {
        var code: String
        var name: String
        var currencyText: String
        var thresholdText: String
        var titleText: String
        var country: String
        var graceDays: String
        var dosageMg: String
        var specialty: String
        var statusLabel: String

        init(code: String, name: String, currencyText: String, thresholdText: String, titleText: String, country: String, graceDays: String, dosageMg: String, specialty: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currencyText = currencyText
            self.thresholdText = thresholdText
            self.titleText = titleText
            self.country = country
            self.graceDays = graceDays
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseSnapshotView(_ item: DispenseSnapshot) -> DispenseSnapshotView {
        return DispenseSnapshotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            currencyText: item.currency,
            thresholdText: String(format: "%.2f", item.threshold),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            country: item.country,
            graceDays: String(item.graceDays),
            dosageMg: String(format: "%.2f", item.dosageMg),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseSnapshotViews(_ items: [DispenseSnapshot]) -> [DispenseSnapshotView] {
        var views: [DispenseSnapshotView] = []
        for item in items {
            views.append(toDispenseSnapshotView(item))
        }
        return views
    }

    static func sumDispenseSnapshotView(_ view: DispenseSnapshotView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays) + parsedDosageMg
    }
}
