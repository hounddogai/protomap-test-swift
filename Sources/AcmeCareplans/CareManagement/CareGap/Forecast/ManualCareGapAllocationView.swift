import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual care gap allocation.
    final class ManualCareGapAllocationView {
        var code: String
        var title: String
        var countryText: String
        var specialty: String
        var copayText: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, title: String, countryText: String, specialty: String, copayText: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.countryText = countryText
            self.specialty = specialty
            self.copayText = copayText
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareGapAllocationView(_ item: ManualCareGapAllocation) -> ManualCareGapAllocationView {
        return ManualCareGapAllocationView(
            code: item.code,
            title: item.title,
            countryText: Kit.Text.truncate(item.country, limit: 80),
            specialty: item.specialty,
            copayText: String(format: "%.2f", item.copay),
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareGapAllocationViews(_ items: [ManualCareGapAllocation]) -> [ManualCareGapAllocationView] {
        var views: [ManualCareGapAllocationView] = []
        for item in items {
            views.append(toManualCareGapAllocationView(item))
        }
        return views
    }

    static func sumManualCareGapAllocationView(_ view: ManualCareGapAllocationView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
