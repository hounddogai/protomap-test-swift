import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered result request.
    final class TieredResultRequestView {
        var code: String
        var title: String
        var channel: String
        var ceiling: String
        var bed: String
        var startsAtText: String
        var patientRef: String
        var revision: String
        var statusLabel: String

        init(code: String, title: String, channel: String, ceiling: String, bed: String, startsAtText: String, patientRef: String, revision: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.channel = channel
            self.ceiling = ceiling
            self.bed = bed
            self.startsAtText = startsAtText
            self.patientRef = patientRef
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toTieredResultRequestView(_ item: TieredResultRequest) -> TieredResultRequestView {
        return TieredResultRequestView(
            code: item.code,
            title: item.title,
            channel: item.channel,
            ceiling: String(format: "%.2f", item.ceiling),
            bed: Kit.Text.truncate(item.bed, limit: 40),
            startsAtText: String(item.startsAt),
            patientRef: item.patientRef,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredResultRequestViews(_ items: [TieredResultRequest]) -> [TieredResultRequestView] {
        var views: [TieredResultRequestView] = []
        for item in items {
            views.append(toTieredResultRequestView(item))
        }
        return views
    }

    static func sumTieredResultRequestView(_ view: TieredResultRequestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCeiling + Double(parsedStartsAt) + Double(parsedRevision)
    }
}
