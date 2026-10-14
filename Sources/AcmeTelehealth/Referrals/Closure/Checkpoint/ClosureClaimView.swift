import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure claim.
    final class ClosureClaimView {
        var code: String
        var nameText: String
        var ratio: String
        var copay: String
        var sequence: String
        var statusLabel: String

        init(code: String, nameText: String, ratio: String, copay: String, sequence: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ratio = ratio
            self.copay = copay
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toClosureClaimView(_ item: ClosureClaim) -> ClosureClaimView {
        return ClosureClaimView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            copay: String(format: "%.2f", item.copay),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureClaimViews(_ items: [ClosureClaim]) -> [ClosureClaimView] {
        var views: [ClosureClaimView] = []
        for item in items {
            views.append(toClosureClaimView(item))
        }
        return views
    }

    static func sumClosureClaimView(_ view: ClosureClaimView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRatio + parsedCopay + Double(parsedSequence)
    }
}
