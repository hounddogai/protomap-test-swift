import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap digest.
    final class CareGapDigestView {
        var codeText: String
        var name: String
        var regionText: String
        var windowDaysText: String
        var description: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, regionText: String, windowDaysText: String, description: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.regionText = regionText
            self.windowDaysText = windowDaysText
            self.description = description
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapDigestView(_ item: CareGapDigest) -> CareGapDigestView {
        return CareGapDigestView(
            codeText: item.code,
            name: item.name,
            regionText: Kit.Text.truncate(item.region, limit: 80),
            windowDaysText: String(item.windowDays),
            description: Kit.Text.truncate(item.description, limit: 40),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapDigestViews(_ items: [CareGapDigest]) -> [CareGapDigestView] {
        var views: [CareGapDigestView] = []
        for item in items {
            views.append(toCareGapDigestView(item))
        }
        return views
    }

    static func sumCareGapDigestView(_ view: CareGapDigestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedQuantity)
    }
}
