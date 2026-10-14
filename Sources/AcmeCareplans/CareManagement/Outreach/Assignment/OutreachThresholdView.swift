import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach threshold.
    final class OutreachThresholdView {
        var code: String
        var titleText: String
        var approved: String
        var limit: String
        var specialty: String
        var ward: String
        var ceiling: String
        var facilityText: String
        var windowDays: String
        var weightText: String
        var statusLabel: String

        init(code: String, titleText: String, approved: String, limit: String, specialty: String, ward: String, ceiling: String, facilityText: String, windowDays: String, weightText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approved = approved
            self.limit = limit
            self.specialty = specialty
            self.ward = ward
            self.ceiling = ceiling
            self.facilityText = facilityText
            self.windowDays = windowDays
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachThresholdView(_ item: OutreachThreshold) -> OutreachThresholdView {
        return OutreachThresholdView(
            code: item.code,
            titleText: item.title,
            approved: "\(item.approved)",
            limit: String(item.limit),
            specialty: item.specialty,
            ward: item.ward,
            ceiling: String(format: "%.2f", item.ceiling),
            facilityText: item.facility,
            windowDays: String(item.windowDays),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachThresholdViews(_ items: [OutreachThreshold]) -> [OutreachThresholdView] {
        var views: [OutreachThresholdView] = []
        for item in items {
            views.append(toOutreachThresholdView(item))
        }
        return views
    }

    static func sumOutreachThresholdView(_ view: OutreachThresholdView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedLimit) + parsedCeiling + Double(parsedWindowDays)
    }
}
