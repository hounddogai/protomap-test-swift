import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional isolation draft.
    final class RegionalIsolationDraftView {
        var code: String
        var name: String
        var clinicianID: String
        var priorityText: String
        var createdAt: String
        var margin: String
        var amount: String
        var dosageMgText: String
        var ownerID: String
        var contactEmail: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, clinicianID: String, priorityText: String, createdAt: String, margin: String, amount: String, dosageMgText: String, ownerID: String, contactEmail: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.priorityText = priorityText
            self.createdAt = createdAt
            self.margin = margin
            self.amount = amount
            self.dosageMgText = dosageMgText
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalIsolationDraftView(_ item: RegionalIsolationDraft) -> RegionalIsolationDraftView {
        return RegionalIsolationDraftView(
            code: item.code,
            name: item.name,
            clinicianID: item.clinicianID,
            priorityText: String(item.priority),
            createdAt: String(item.createdAt),
            margin: String(format: "%.2f", item.margin),
            amount: String(format: "%.2f", item.amount),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            ownerID: item.ownerID,
            contactEmail: item.contactEmail,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalIsolationDraftViews(_ items: [RegionalIsolationDraft]) -> [RegionalIsolationDraftView] {
        var views: [RegionalIsolationDraftView] = []
        for item in items {
            views.append(toRegionalIsolationDraftView(item))
        }
        return views
    }

    static func sumRegionalIsolationDraftView(_ view: RegionalIsolationDraftView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedPriority) + Double(parsedCreatedAt) + parsedMargin
    }
}
