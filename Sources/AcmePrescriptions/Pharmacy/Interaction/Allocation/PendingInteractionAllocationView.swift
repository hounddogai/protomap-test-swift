import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending interaction allocation.
    final class PendingInteractionAllocationView {
        var code: String
        var label: String
        var endsAtText: String
        var expiresAt: String
        var retries: String
        var facilityText: String
        var patientRefText: String
        var batchSizeText: String
        var approved: String
        var marginText: String
        var statusLabel: String

        init(code: String, label: String, endsAtText: String, expiresAt: String, retries: String, facilityText: String, patientRefText: String, batchSizeText: String, approved: String, marginText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAtText = endsAtText
            self.expiresAt = expiresAt
            self.retries = retries
            self.facilityText = facilityText
            self.patientRefText = patientRefText
            self.batchSizeText = batchSizeText
            self.approved = approved
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingInteractionAllocationView(_ item: PendingInteractionAllocation) -> PendingInteractionAllocationView {
        return PendingInteractionAllocationView(
            code: item.code,
            label: item.label,
            endsAtText: String(item.endsAt),
            expiresAt: String(item.expiresAt),
            retries: String(item.retries),
            facilityText: item.facility,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            batchSizeText: String(item.batchSize),
            approved: "\(item.approved)",
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingInteractionAllocationViews(_ items: [PendingInteractionAllocation]) -> [PendingInteractionAllocationView] {
        var views: [PendingInteractionAllocationView] = []
        for item in items {
            views.append(toPendingInteractionAllocationView(item))
        }
        return views
    }

    static func sumPendingInteractionAllocationView(_ view: PendingInteractionAllocationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedExpiresAt) + Double(parsedRetries)
    }
}
