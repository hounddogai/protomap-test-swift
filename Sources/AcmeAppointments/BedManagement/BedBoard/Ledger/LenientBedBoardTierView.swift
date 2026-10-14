import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient bed board tier.
    final class LenientBedBoardTierView {
        var codeText: String
        var name: String
        var ward: String
        var localeText: String
        var country: String
        var endsAt: String
        var createdAt: String
        var bedText: String
        var weightText: String
        var clinicianID: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, name: String, ward: String, localeText: String, country: String, endsAt: String, createdAt: String, bedText: String, weightText: String, clinicianID: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ward = ward
            self.localeText = localeText
            self.country = country
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.bedText = bedText
            self.weightText = weightText
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toLenientBedBoardTierView(_ item: LenientBedBoardTier) -> LenientBedBoardTierView {
        return LenientBedBoardTierView(
            codeText: item.code,
            name: item.name,
            ward: item.ward,
            localeText: item.locale,
            country: Kit.Text.truncate(item.country, limit: 80),
            endsAt: String(item.endsAt),
            createdAt: String(item.createdAt),
            bedText: item.bed,
            weightText: String(format: "%.2f", item.weight),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientBedBoardTierViews(_ items: [LenientBedBoardTier]) -> [LenientBedBoardTierView] {
        var views: [LenientBedBoardTierView] = []
        for item in items {
            views.append(toLenientBedBoardTierView(item))
        }
        return views
    }

    static func sumLenientBedBoardTierView(_ view: LenientBedBoardTierView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCreatedAt) + parsedWeight
    }
}
