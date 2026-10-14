import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped read digest.
    final class CappedReadDigestView {
        var code: String
        var name: String
        var rate: String
        var bed: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, name: String, rate: String, bed: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.rate = rate
            self.bed = bed
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReadDigestView(_ item: CappedReadDigest) -> CappedReadDigestView {
        return CappedReadDigestView(
            code: item.code,
            name: item.name,
            rate: String(format: "%.2f", item.rate),
            bed: item.bed,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReadDigestViews(_ items: [CappedReadDigest]) -> [CappedReadDigestView] {
        var views: [CappedReadDigestView] = []
        for item in items {
            views.append(toCappedReadDigestView(item))
        }
        return views
    }

    static func sumCappedReadDigestView(_ view: CappedReadDigestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedRate + Double(parsedExpiresAt)
    }
}
