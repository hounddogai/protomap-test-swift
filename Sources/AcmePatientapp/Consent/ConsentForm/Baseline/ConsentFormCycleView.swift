import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form cycle.
    final class ConsentFormCycleView {
        var code: String
        var name: String
        var limit: String
        var channel: String
        var visitMinutes: String
        var payer: String
        var approvedText: String
        var segmentText: String
        var statusLabel: String

        init(code: String, name: String, limit: String, channel: String, visitMinutes: String, payer: String, approvedText: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.channel = channel
            self.visitMinutes = visitMinutes
            self.payer = payer
            self.approvedText = approvedText
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormCycleView(_ item: ConsentFormCycle) -> ConsentFormCycleView {
        return ConsentFormCycleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            limit: String(item.limit),
            channel: item.channel,
            visitMinutes: String(item.visitMinutes),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            approvedText: "\(item.approved)",
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormCycleViews(_ items: [ConsentFormCycle]) -> [ConsentFormCycleView] {
        var views: [ConsentFormCycleView] = []
        for item in items {
            views.append(toConsentFormCycleView(item))
        }
        return views
    }

    static func sumConsentFormCycleView(_ view: ConsentFormCycleView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedLimit) + Double(parsedVisitMinutes)
    }
}
