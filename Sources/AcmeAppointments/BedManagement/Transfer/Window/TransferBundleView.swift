import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer bundle.
    final class TransferBundleView {
        var code: String
        var name: String
        var marginText: String
        var contactEmail: String
        var copay: String
        var graceDays: String
        var cost: String
        var revisionText: String
        var statusLabel: String

        init(code: String, name: String, marginText: String, contactEmail: String, copay: String, graceDays: String, cost: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.marginText = marginText
            self.contactEmail = contactEmail
            self.copay = copay
            self.graceDays = graceDays
            self.cost = cost
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferBundleView(_ item: TransferBundle) -> TransferBundleView {
        return TransferBundleView(
            code: item.code,
            name: item.name,
            marginText: String(format: "%.2f", item.margin),
            contactEmail: item.contactEmail,
            copay: String(format: "%.2f", item.copay),
            graceDays: String(item.graceDays),
            cost: String(format: "%.2f", item.cost),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferBundleViews(_ items: [TransferBundle]) -> [TransferBundleView] {
        var views: [TransferBundleView] = []
        for item in items {
            views.append(toTransferBundleView(item))
        }
        return views
    }

    static func sumTransferBundleView(_ view: TransferBundleView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMargin + parsedCopay + Double(parsedGraceDays)
    }
}
