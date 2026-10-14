import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census request.
    final class CensusRequestView {
        var code: String
        var label: String
        var segment: String
        var margin: String
        var wardText: String
        var summary: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(code: String, label: String, segment: String, margin: String, wardText: String, summary: String, diagnosisCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.margin = margin
            self.wardText = wardText
            self.summary = summary
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusRequestView(_ item: CensusRequest) -> CensusRequestView {
        return CensusRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            margin: String(format: "%.2f", item.margin),
            wardText: item.ward,
            summary: Kit.Text.truncate(item.summary, limit: 80),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusRequestViews(_ items: [CensusRequest]) -> [CensusRequestView] {
        var views: [CensusRequestView] = []
        for item in items {
            views.append(toCensusRequestView(item))
        }
        return views
    }

    static func sumCensusRequestView(_ view: CensusRequestView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
