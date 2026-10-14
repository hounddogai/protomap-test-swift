import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending result metric.
    final class PendingResultMetricView {
        var code: String
        var labelText: String
        var externalRefText: String
        var floorValueText: String
        var sequence: String
        var channel: String
        var countryText: String
        var dosageMgText: String
        var margin: String
        var statusLabel: String

        init(code: String, labelText: String, externalRefText: String, floorValueText: String, sequence: String, channel: String, countryText: String, dosageMgText: String, margin: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.externalRefText = externalRefText
            self.floorValueText = floorValueText
            self.sequence = sequence
            self.channel = channel
            self.countryText = countryText
            self.dosageMgText = dosageMgText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toPendingResultMetricView(_ item: PendingResultMetric) -> PendingResultMetricView {
        return PendingResultMetricView(
            code: item.code,
            labelText: item.label,
            externalRefText: item.externalRef,
            floorValueText: String(format: "%.2f", item.floorValue),
            sequence: String(item.sequence),
            channel: item.channel,
            countryText: item.country,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingResultMetricViews(_ items: [PendingResultMetric]) -> [PendingResultMetricView] {
        var views: [PendingResultMetricView] = []
        for item in items {
            views.append(toPendingResultMetricView(item))
        }
        return views
    }

    static func sumPendingResultMetricView(_ view: PendingResultMetricView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedFloorValue + Double(parsedSequence) + parsedDosageMg
    }
}
