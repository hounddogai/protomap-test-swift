import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered shift bundle.
    final class TieredShiftBundleView {
        var codeText: String
        var title: String
        var durationMinutesText: String
        var externalRef: String
        var approved: String
        var discount: String
        var createdAt: String
        var attempts: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutesText: String, externalRef: String, approved: String, discount: String, createdAt: String, attempts: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutesText = durationMinutesText
            self.externalRef = externalRef
            self.approved = approved
            self.discount = discount
            self.createdAt = createdAt
            self.attempts = attempts
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toTieredShiftBundleView(_ item: TieredShiftBundle) -> TieredShiftBundleView {
        return TieredShiftBundleView(
            codeText: item.code,
            title: item.title,
            durationMinutesText: String(item.durationMinutes),
            externalRef: item.externalRef,
            approved: "\(item.approved)",
            discount: String(format: "%.2f", item.discount),
            createdAt: String(item.createdAt),
            attempts: String(item.attempts),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredShiftBundleViews(_ items: [TieredShiftBundle]) -> [TieredShiftBundleView] {
        var views: [TieredShiftBundleView] = []
        for item in items {
            views.append(toTieredShiftBundleView(item))
        }
        return views
    }

    static func sumTieredShiftBundleView(_ view: TieredShiftBundleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedDurationMinutes) + parsedDiscount + Double(parsedCreatedAt)
    }
}
