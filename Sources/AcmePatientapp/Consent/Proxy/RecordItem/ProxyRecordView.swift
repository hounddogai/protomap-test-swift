import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy record.
    final class ProxyRecordView {
        var code: String
        var name: String
        var visitMinutesText: String
        var graceDays: String
        var acuity: String
        var clinicianID: String
        var floorValue: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, visitMinutesText: String, graceDays: String, acuity: String, clinicianID: String, floorValue: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutesText = visitMinutesText
            self.graceDays = graceDays
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toProxyRecordView(_ item: ProxyRecord) -> ProxyRecordView {
        return ProxyRecordView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            visitMinutesText: String(item.visitMinutes),
            graceDays: String(item.graceDays),
            acuity: String(item.acuity),
            clinicianID: item.clinicianID,
            floorValue: String(format: "%.2f", item.floorValue),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyRecordViews(_ items: [ProxyRecord]) -> [ProxyRecordView] {
        var views: [ProxyRecordView] = []
        for item in items {
            views.append(toProxyRecordView(item))
        }
        return views
    }

    static func sumProxyRecordView(_ view: ProxyRecordView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedGraceDays) + Double(parsedAcuity)
    }
}
