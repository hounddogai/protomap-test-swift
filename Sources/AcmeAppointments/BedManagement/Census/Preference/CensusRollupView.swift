import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census rollup.
    final class CensusRollupView {
        var code: String
        var name: String
        var facility: String
        var rateText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, facility: String, rateText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facility = facility
            self.rateText = rateText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toCensusRollupView(_ item: CensusRollup) -> CensusRollupView {
        return CensusRollupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusRollupViews(_ items: [CensusRollup]) -> [CensusRollupView] {
        var views: [CensusRollupView] = []
        for item in items {
            views.append(toCensusRollupView(item))
        }
        return views
    }

    static func sumCensusRollupView(_ view: CensusRollupView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
