import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted credential entry.
    final class WeightedCredentialEntryView {
        var codeText: String
        var name: String
        var approved: String
        var ownerID: String
        var sequence: String
        var refills: String
        var rate: String
        var limitText: String
        var windowDays: String
        var description: String
        var statusLabel: String

        init(codeText: String, name: String, approved: String, ownerID: String, sequence: String, refills: String, rate: String, limitText: String, windowDays: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.approved = approved
            self.ownerID = ownerID
            self.sequence = sequence
            self.refills = refills
            self.rate = rate
            self.limitText = limitText
            self.windowDays = windowDays
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCredentialEntryView(_ item: WeightedCredentialEntry) -> WeightedCredentialEntryView {
        return WeightedCredentialEntryView(
            codeText: item.code,
            name: item.name,
            approved: "\(item.approved)",
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            sequence: String(item.sequence),
            refills: String(item.refills),
            rate: String(format: "%.2f", item.rate),
            limitText: String(item.limit),
            windowDays: String(item.windowDays),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCredentialEntryViews(_ items: [WeightedCredentialEntry]) -> [WeightedCredentialEntryView] {
        var views: [WeightedCredentialEntryView] = []
        for item in items {
            views.append(toWeightedCredentialEntryView(item))
        }
        return views
    }

    static func sumWeightedCredentialEntryView(_ view: WeightedCredentialEntryView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedSequence) + Double(parsedRefills) + parsedRate
    }
}
