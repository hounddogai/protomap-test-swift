import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff record.
    final class HandoffRecordView {
        var code: String
        var title: String
        var approvedText: String
        var cost: String
        var specialty: String
        var facility: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, title: String, approvedText: String, cost: String, specialty: String, facility: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approvedText = approvedText
            self.cost = cost
            self.specialty = specialty
            self.facility = facility
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffRecordView(_ item: HandoffRecord) -> HandoffRecordView {
        return HandoffRecordView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            approvedText: "\(item.approved)",
            cost: String(format: "%.2f", item.cost),
            specialty: item.specialty,
            facility: item.facility,
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffRecordViews(_ items: [HandoffRecord]) -> [HandoffRecordView] {
        var views: [HandoffRecordView] = []
        for item in items {
            views.append(toHandoffRecordView(item))
        }
        return views
    }

    static func sumHandoffRecordView(_ view: HandoffRecordView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCost + Double(parsedDurationMinutes)
    }
}
