import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary acuity plan target.
    final class PrimaryAcuityPlanTargetView {
        var codeText: String
        var title: String
        var version: String
        var ward: String
        var discountText: String
        var updatedAt: String
        var createdAt: String
        var segmentText: String
        var margin: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, title: String, version: String, ward: String, discountText: String, updatedAt: String, createdAt: String, segmentText: String, margin: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.version = version
            self.ward = ward
            self.discountText = discountText
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.segmentText = segmentText
            self.margin = margin
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAcuityPlanTargetView(_ item: PrimaryAcuityPlanTarget) -> PrimaryAcuityPlanTargetView {
        return PrimaryAcuityPlanTargetView(
            codeText: item.code,
            title: item.title,
            version: String(item.version),
            ward: item.ward,
            discountText: String(format: "%.2f", item.discount),
            updatedAt: String(item.updatedAt),
            createdAt: String(item.createdAt),
            segmentText: item.segment,
            margin: String(format: "%.2f", item.margin),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAcuityPlanTargetViews(_ items: [PrimaryAcuityPlanTarget]) -> [PrimaryAcuityPlanTargetView] {
        var views: [PrimaryAcuityPlanTargetView] = []
        for item in items {
            views.append(toPrimaryAcuityPlanTargetView(item))
        }
        return views
    }

    static func sumPrimaryAcuityPlanTargetView(_ view: PrimaryAcuityPlanTargetView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVersion) + parsedDiscount + Double(parsedUpdatedAt)
    }
}
