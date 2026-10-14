import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched transfer claim.
    final class BatchedTransferClaimView {
        var code: String
        var name: String
        var weight: String
        var durationMinutes: String
        var specialtyText: String
        var region: String
        var endsAtText: String
        var channel: String
        var retriesText: String
        var approved: String
        var priority: String
        var statusLabel: String

        init(code: String, name: String, weight: String, durationMinutes: String, specialtyText: String, region: String, endsAtText: String, channel: String, retriesText: String, approved: String, priority: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.specialtyText = specialtyText
            self.region = region
            self.endsAtText = endsAtText
            self.channel = channel
            self.retriesText = retriesText
            self.approved = approved
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedTransferClaimView(_ item: BatchedTransferClaim) -> BatchedTransferClaimView {
        return BatchedTransferClaimView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            durationMinutes: String(item.durationMinutes),
            specialtyText: item.specialty,
            region: Kit.Text.truncate(item.region, limit: 120),
            endsAtText: String(item.endsAt),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            retriesText: String(item.retries),
            approved: "\(item.approved)",
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedTransferClaimViews(_ items: [BatchedTransferClaim]) -> [BatchedTransferClaimView] {
        var views: [BatchedTransferClaimView] = []
        for item in items {
            views.append(toBatchedTransferClaimView(item))
        }
        return views
    }

    static func sumBatchedTransferClaimView(_ view: BatchedTransferClaimView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedWeight + Double(parsedDurationMinutes) + Double(parsedEndsAt)
    }
}
