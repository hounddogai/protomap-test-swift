import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched network claim.
    final class BatchedNetworkClaimView {
        var codeText: String
        var label: String
        var checksumText: String
        var budgetText: String
        var encounterID: String
        var phoneText: String
        var unit: String
        var specialty: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, label: String, checksumText: String, budgetText: String, encounterID: String, phoneText: String, unit: String, specialty: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.checksumText = checksumText
            self.budgetText = budgetText
            self.encounterID = encounterID
            self.phoneText = phoneText
            self.unit = unit
            self.specialty = specialty
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedNetworkClaimView(_ item: BatchedNetworkClaim) -> BatchedNetworkClaimView {
        return BatchedNetworkClaimView(
            codeText: item.code,
            label: item.label,
            checksumText: item.checksum,
            budgetText: String(format: "%.2f", item.budget),
            encounterID: item.encounterID,
            phoneText: item.phone,
            unit: item.unit,
            specialty: item.specialty,
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedNetworkClaimViews(_ items: [BatchedNetworkClaim]) -> [BatchedNetworkClaimView] {
        var views: [BatchedNetworkClaimView] = []
        for item in items {
            views.append(toBatchedNetworkClaimView(item))
        }
        return views
    }

    static func sumBatchedNetworkClaimView(_ view: BatchedNetworkClaimView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
