import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set digest.
    final class OrderSetDigestView {
        var codeText: String
        var titleText: String
        var regionText: String
        var currency: String
        var batchSizeText: String
        var descriptionText: String
        var patientRefText: String
        var revision: String
        var bedText: String
        var allergyText: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, titleText: String, regionText: String, currency: String, batchSizeText: String, descriptionText: String, patientRefText: String, revision: String, bedText: String, allergyText: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.regionText = regionText
            self.currency = currency
            self.batchSizeText = batchSizeText
            self.descriptionText = descriptionText
            self.patientRefText = patientRefText
            self.revision = revision
            self.bedText = bedText
            self.allergyText = allergyText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetDigestView(_ item: OrderSetDigest) -> OrderSetDigestView {
        return OrderSetDigestView(
            codeText: item.code,
            titleText: item.title,
            regionText: item.region,
            currency: item.currency,
            batchSizeText: String(item.batchSize),
            descriptionText: item.description,
            patientRefText: item.patientRef,
            revision: String(item.revision),
            bedText: item.bed,
            allergyText: item.allergy,
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetDigestViews(_ items: [OrderSetDigest]) -> [OrderSetDigestView] {
        var views: [OrderSetDigestView] = []
        for item in items {
            views.append(toOrderSetDigestView(item))
        }
        return views
    }

    static func sumOrderSetDigestView(_ view: OrderSetDigestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRevision) + Double(parsedWindowDays)
    }
}
