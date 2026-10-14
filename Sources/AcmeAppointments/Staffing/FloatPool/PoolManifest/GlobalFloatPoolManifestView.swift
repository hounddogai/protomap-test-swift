import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global float pool manifest.
    final class GlobalFloatPoolManifestView {
        var code: String
        var title: String
        var minimumText: String
        var createdAtText: String
        var amountText: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, minimumText: String, createdAtText: String, amountText: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimumText = minimumText
            self.createdAtText = createdAtText
            self.amountText = amountText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFloatPoolManifestView(_ item: GlobalFloatPoolManifest) -> GlobalFloatPoolManifestView {
        return GlobalFloatPoolManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            minimumText: String(format: "%.2f", item.minimum),
            createdAtText: String(item.createdAt),
            amountText: String(format: "%.2f", item.amount),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFloatPoolManifestViews(_ items: [GlobalFloatPoolManifest]) -> [GlobalFloatPoolManifestView] {
        var views: [GlobalFloatPoolManifestView] = []
        for item in items {
            views.append(toGlobalFloatPoolManifestView(item))
        }
        return views
    }

    static func sumGlobalFloatPoolManifestView(_ view: GlobalFloatPoolManifestView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedMinimum + Double(parsedCreatedAt) + parsedAmount
    }
}
