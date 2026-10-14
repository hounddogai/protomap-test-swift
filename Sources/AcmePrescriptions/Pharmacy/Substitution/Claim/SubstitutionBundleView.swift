import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution bundle.
    final class SubstitutionBundleView {
        var code: String
        var nameText: String
        var ward: String
        var limitText: String
        var title: String
        var weight: String
        var archived: String
        var reviewerText: String
        var checksum: String
        var regionText: String
        var statusLabel: String

        init(code: String, nameText: String, ward: String, limitText: String, title: String, weight: String, archived: String, reviewerText: String, checksum: String, regionText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ward = ward
            self.limitText = limitText
            self.title = title
            self.weight = weight
            self.archived = archived
            self.reviewerText = reviewerText
            self.checksum = checksum
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionBundleView(_ item: SubstitutionBundle) -> SubstitutionBundleView {
        return SubstitutionBundleView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            ward: item.ward,
            limitText: String(item.limit),
            title: item.title,
            weight: String(format: "%.2f", item.weight),
            archived: "\(item.archived)",
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 64),
            checksum: item.checksum,
            regionText: Kit.Text.truncate(item.region, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionBundleViews(_ items: [SubstitutionBundle]) -> [SubstitutionBundleView] {
        var views: [SubstitutionBundleView] = []
        for item in items {
            views.append(toSubstitutionBundleView(item))
        }
        return views
    }

    static func sumSubstitutionBundleView(_ view: SubstitutionBundleView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedLimit) + parsedWeight
    }
}
