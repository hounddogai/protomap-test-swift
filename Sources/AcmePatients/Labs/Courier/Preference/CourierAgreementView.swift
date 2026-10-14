import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier agreement.
    final class CourierAgreementView {
        var code: String
        var name: String
        var unitText: String
        var floorValueText: String
        var label: String
        var summaryText: String
        var expiresAtText: String
        var refills: String
        var reviewer: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, unitText: String, floorValueText: String, label: String, summaryText: String, expiresAtText: String, refills: String, reviewer: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unitText = unitText
            self.floorValueText = floorValueText
            self.label = label
            self.summaryText = summaryText
            self.expiresAtText = expiresAtText
            self.refills = refills
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCourierAgreementView(_ item: CourierAgreement) -> CourierAgreementView {
        return CourierAgreementView(
            code: item.code,
            name: item.name,
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            floorValueText: String(format: "%.2f", item.floorValue),
            label: Kit.Text.truncate(item.label, limit: 64),
            summaryText: item.summary,
            expiresAtText: String(item.expiresAt),
            refills: String(item.refills),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierAgreementViews(_ items: [CourierAgreement]) -> [CourierAgreementView] {
        var views: [CourierAgreementView] = []
        for item in items {
            views.append(toCourierAgreementView(item))
        }
        return views
    }

    static func sumCourierAgreementView(_ view: CourierAgreementView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedFloorValue + Double(parsedExpiresAt) + Double(parsedRefills)
    }
}
