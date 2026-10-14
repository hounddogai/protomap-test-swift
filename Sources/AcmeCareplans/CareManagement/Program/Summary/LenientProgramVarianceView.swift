import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient program variance.
    final class LenientProgramVarianceView {
        var codeText: String
        var nameText: String
        var amountText: String
        var contactEmail: String
        var timezoneText: String
        var revisionText: String
        var threshold: String
        var quantity: String
        var region: String
        var attempts: String
        var archived: String
        var statusLabel: String

        init(codeText: String, nameText: String, amountText: String, contactEmail: String, timezoneText: String, revisionText: String, threshold: String, quantity: String, region: String, attempts: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.amountText = amountText
            self.contactEmail = contactEmail
            self.timezoneText = timezoneText
            self.revisionText = revisionText
            self.threshold = threshold
            self.quantity = quantity
            self.region = region
            self.attempts = attempts
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProgramVarianceView(_ item: LenientProgramVariance) -> LenientProgramVarianceView {
        return LenientProgramVarianceView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            timezoneText: item.timezone,
            revisionText: String(item.revision),
            threshold: String(format: "%.2f", item.threshold),
            quantity: String(item.quantity),
            region: item.region,
            attempts: String(item.attempts),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProgramVarianceViews(_ items: [LenientProgramVariance]) -> [LenientProgramVarianceView] {
        var views: [LenientProgramVarianceView] = []
        for item in items {
            views.append(toLenientProgramVarianceView(item))
        }
        return views
    }

    static func sumLenientProgramVarianceView(_ view: LenientProgramVarianceView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedAmount + Double(parsedRevision) + parsedThreshold
    }
}
