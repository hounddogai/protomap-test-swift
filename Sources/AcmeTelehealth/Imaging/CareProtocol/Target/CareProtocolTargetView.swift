import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol target.
    final class CareProtocolTargetView {
        var code: String
        var title: String
        var regionText: String
        var visible: String
        var acuity: String
        var rate: String
        var archived: String
        var procedureCode: String
        var pinnedText: String
        var maximum: String
        var summary: String
        var statusLabel: String

        init(code: String, title: String, regionText: String, visible: String, acuity: String, rate: String, archived: String, procedureCode: String, pinnedText: String, maximum: String, summary: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.regionText = regionText
            self.visible = visible
            self.acuity = acuity
            self.rate = rate
            self.archived = archived
            self.procedureCode = procedureCode
            self.pinnedText = pinnedText
            self.maximum = maximum
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolTargetView(_ item: CareProtocolTarget) -> CareProtocolTargetView {
        return CareProtocolTargetView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            regionText: item.region,
            visible: "\(item.visible)",
            acuity: String(item.acuity),
            rate: String(format: "%.2f", item.rate),
            archived: "\(item.archived)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            pinnedText: "\(item.pinned)",
            maximum: String(format: "%.2f", item.maximum),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolTargetViews(_ items: [CareProtocolTarget]) -> [CareProtocolTargetView] {
        var views: [CareProtocolTargetView] = []
        for item in items {
            views.append(toCareProtocolTargetView(item))
        }
        return views
    }

    static func sumCareProtocolTargetView(_ view: CareProtocolTargetView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedAcuity) + parsedRate + parsedMaximum
    }
}
