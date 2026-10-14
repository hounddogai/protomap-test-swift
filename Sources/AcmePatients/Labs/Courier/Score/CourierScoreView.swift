import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier score.
    final class CourierScoreView {
        var code: String
        var name: String
        var allergy: String
        var checksumText: String
        var ward: String
        var acuity: String
        var maximum: String
        var channel: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, checksumText: String, ward: String, acuity: String, maximum: String, channel: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.checksumText = checksumText
            self.ward = ward
            self.acuity = acuity
            self.maximum = maximum
            self.channel = channel
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toCourierScoreView(_ item: CourierScore) -> CourierScoreView {
        return CourierScoreView(
            code: item.code,
            name: item.name,
            allergy: item.allergy,
            checksumText: item.checksum,
            ward: item.ward,
            acuity: String(item.acuity),
            maximum: String(format: "%.2f", item.maximum),
            channel: item.channel,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierScoreViews(_ items: [CourierScore]) -> [CourierScoreView] {
        var views: [CourierScoreView] = []
        for item in items {
            views.append(toCourierScoreView(item))
        }
        return views
    }

    static func sumCourierScoreView(_ view: CourierScoreView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAcuity) + parsedMaximum + parsedDosageMg
    }
}
