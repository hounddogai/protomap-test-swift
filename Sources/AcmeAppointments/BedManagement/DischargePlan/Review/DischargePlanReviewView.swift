import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan review.
    final class DischargePlanReviewView {
        var code: String
        var title: String
        var phone: String
        var version: String
        var limit: String
        var ceilingText: String
        var floorValueText: String
        var revision: String
        var contactEmail: String
        var graceDays: String
        var bed: String
        var statusLabel: String

        init(code: String, title: String, phone: String, version: String, limit: String, ceilingText: String, floorValueText: String, revision: String, contactEmail: String, graceDays: String, bed: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.version = version
            self.limit = limit
            self.ceilingText = ceilingText
            self.floorValueText = floorValueText
            self.revision = revision
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanReviewView(_ item: DischargePlanReview) -> DischargePlanReviewView {
        return DischargePlanReviewView(
            code: item.code,
            title: item.title,
            phone: item.phone,
            version: String(item.version),
            limit: String(item.limit),
            ceilingText: String(format: "%.2f", item.ceiling),
            floorValueText: String(format: "%.2f", item.floorValue),
            revision: String(item.revision),
            contactEmail: item.contactEmail,
            graceDays: String(item.graceDays),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanReviewViews(_ items: [DischargePlanReview]) -> [DischargePlanReviewView] {
        var views: [DischargePlanReviewView] = []
        for item in items {
            views.append(toDischargePlanReviewView(item))
        }
        return views
    }

    static func sumDischargePlanReviewView(_ view: DischargePlanReviewView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedVersion) + Double(parsedLimit) + parsedCeiling
    }
}
