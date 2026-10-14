import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen review.
    final class SpecimenReviewView {
        var codeText: String
        var labelText: String
        var capacityText: String
        var region: String
        var description: String
        var batchSize: String
        var approved: String
        var allergyText: String
        var copay: String
        var checksum: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, labelText: String, capacityText: String, region: String, description: String, batchSize: String, approved: String, allergyText: String, copay: String, checksum: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.capacityText = capacityText
            self.region = region
            self.description = description
            self.batchSize = batchSize
            self.approved = approved
            self.allergyText = allergyText
            self.copay = copay
            self.checksum = checksum
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenReviewView(_ item: SpecimenReview) -> SpecimenReviewView {
        return SpecimenReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            capacityText: String(item.capacity),
            region: Kit.Text.truncate(item.region, limit: 80),
            description: Kit.Text.truncate(item.description, limit: 80),
            batchSize: String(item.batchSize),
            approved: "\(item.approved)",
            allergyText: Kit.Text.truncate(item.allergy, limit: 120),
            copay: String(format: "%.2f", item.copay),
            checksum: item.checksum,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenReviewViews(_ items: [SpecimenReview]) -> [SpecimenReviewView] {
        var views: [SpecimenReviewView] = []
        for item in items {
            views.append(toSpecimenReviewView(item))
        }
        return views
    }

    static func sumSpecimenReviewView(_ view: SpecimenReviewView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedCapacity) + Double(parsedBatchSize) + parsedCopay
    }
}
