import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census bundle.
    final class CensusBundleView {
        var codeText: String
        var title: String
        var channelText: String
        var active: String
        var facility: String
        var bed: String
        var ceilingText: String
        var locale: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, title: String, channelText: String, active: String, facility: String, bed: String, ceilingText: String, locale: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.channelText = channelText
            self.active = active
            self.facility = facility
            self.bed = bed
            self.ceilingText = ceilingText
            self.locale = locale
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toCensusBundleView(_ item: CensusBundle) -> CensusBundleView {
        return CensusBundleView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            active: "\(item.active)",
            facility: item.facility,
            bed: item.bed,
            ceilingText: String(format: "%.2f", item.ceiling),
            locale: Kit.Text.truncate(item.locale, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusBundleViews(_ items: [CensusBundle]) -> [CensusBundleView] {
        var views: [CensusBundleView] = []
        for item in items {
            views.append(toCensusBundleView(item))
        }
        return views
    }

    static func sumCensusBundleView(_ view: CensusBundleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedMaximum
    }
}
