import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped handoff mapping.
    final class CappedHandoffMappingView {
        var code: String
        var nameText: String
        var ownerIDText: String
        var revision: String
        var approved: String
        var weight: String
        var expiresAt: String
        var copay: String
        var archivedText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, nameText: String, ownerIDText: String, revision: String, approved: String, weight: String, expiresAt: String, copay: String, archivedText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ownerIDText = ownerIDText
            self.revision = revision
            self.approved = approved
            self.weight = weight
            self.expiresAt = expiresAt
            self.copay = copay
            self.archivedText = archivedText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedHandoffMappingView(_ item: CappedHandoffMapping) -> CappedHandoffMappingView {
        return CappedHandoffMappingView(
            code: item.code,
            nameText: item.name,
            ownerIDText: item.ownerID,
            revision: String(item.revision),
            approved: "\(item.approved)",
            weight: String(format: "%.2f", item.weight),
            expiresAt: String(item.expiresAt),
            copay: String(format: "%.2f", item.copay),
            archivedText: "\(item.archived)",
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedHandoffMappingViews(_ items: [CappedHandoffMapping]) -> [CappedHandoffMappingView] {
        var views: [CappedHandoffMappingView] = []
        for item in items {
            views.append(toCappedHandoffMappingView(item))
        }
        return views
    }

    static func sumCappedHandoffMappingView(_ view: CappedHandoffMappingView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRevision) + parsedWeight + Double(parsedExpiresAt)
    }
}
