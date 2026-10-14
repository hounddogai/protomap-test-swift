import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted network baseline.
    final class WeightedNetworkBaselineView {
        var codeText: String
        var title: String
        var createdAtText: String
        var phoneText: String
        var name: String
        var facility: String
        var durationMinutes: String
        var patientRef: String
        var approved: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, title: String, createdAtText: String, phoneText: String, name: String, facility: String, durationMinutes: String, patientRef: String, approved: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.createdAtText = createdAtText
            self.phoneText = phoneText
            self.name = name
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.approved = approved
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedNetworkBaselineView(_ item: WeightedNetworkBaseline) -> WeightedNetworkBaselineView {
        return WeightedNetworkBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            createdAtText: String(item.createdAt),
            phoneText: item.phone,
            name: Kit.Text.truncate(item.name, limit: 80),
            facility: item.facility,
            durationMinutes: String(item.durationMinutes),
            patientRef: item.patientRef,
            approved: "\(item.approved)",
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedNetworkBaselineViews(_ items: [WeightedNetworkBaseline]) -> [WeightedNetworkBaselineView] {
        var views: [WeightedNetworkBaselineView] = []
        for item in items {
            views.append(toWeightedNetworkBaselineView(item))
        }
        return views
    }

    static func sumWeightedNetworkBaselineView(_ view: WeightedNetworkBaselineView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedDurationMinutes) + Double(parsedVisitMinutes)
    }
}
