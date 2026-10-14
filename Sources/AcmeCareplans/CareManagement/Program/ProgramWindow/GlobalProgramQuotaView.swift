import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global program quota.
    final class GlobalProgramQuotaView {
        var code: String
        var title: String
        var segmentText: String
        var discountText: String
        var countryText: String
        var clinicianID: String
        var dosageMgText: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, title: String, segmentText: String, discountText: String, countryText: String, clinicianID: String, dosageMgText: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segmentText = segmentText
            self.discountText = discountText
            self.countryText = countryText
            self.clinicianID = clinicianID
            self.dosageMgText = dosageMgText
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalProgramQuotaView(_ item: GlobalProgramQuota) -> GlobalProgramQuotaView {
        return GlobalProgramQuotaView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            discountText: String(format: "%.2f", item.discount),
            countryText: item.country,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalProgramQuotaViews(_ items: [GlobalProgramQuota]) -> [GlobalProgramQuotaView] {
        var views: [GlobalProgramQuotaView] = []
        for item in items {
            views.append(toGlobalProgramQuotaView(item))
        }
        return views
    }

    static func sumGlobalProgramQuotaView(_ view: GlobalProgramQuotaView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedDiscount + parsedDosageMg + Double(parsedWindowDays)
    }
}
