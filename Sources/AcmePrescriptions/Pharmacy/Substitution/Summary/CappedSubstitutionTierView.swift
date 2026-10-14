import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped substitution tier.
    final class CappedSubstitutionTierView {
        var codeText: String
        var name: String
        var region: String
        var refills: String
        var notes: String
        var amount: String
        var revision: String
        var checksum: String
        var visible: String
        var statusLabel: String

        init(codeText: String, name: String, region: String, refills: String, notes: String, amount: String, revision: String, checksum: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.region = region
            self.refills = refills
            self.notes = notes
            self.amount = amount
            self.revision = revision
            self.checksum = checksum
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSubstitutionTierView(_ item: CappedSubstitutionTier) -> CappedSubstitutionTierView {
        return CappedSubstitutionTierView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 120),
            region: item.region,
            refills: String(item.refills),
            notes: item.notes,
            amount: String(format: "%.2f", item.amount),
            revision: String(item.revision),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSubstitutionTierViews(_ items: [CappedSubstitutionTier]) -> [CappedSubstitutionTierView] {
        var views: [CappedSubstitutionTierView] = []
        for item in items {
            views.append(toCappedSubstitutionTierView(item))
        }
        return views
    }

    static func sumCappedSubstitutionTierView(_ view: CappedSubstitutionTierView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRefills) + parsedAmount + Double(parsedRevision)
    }
}
