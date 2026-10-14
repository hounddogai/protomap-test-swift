import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending care gap allocation.
    final class PendingCareGapAllocationView {
        var code: String
        var title: String
        var procedureCode: String
        var bed: String
        var endsAtText: String
        var maximum: String
        var discountText: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, bed: String, endsAtText: String, maximum: String, discountText: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.bed = bed
            self.endsAtText = endsAtText
            self.maximum = maximum
            self.discountText = discountText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCareGapAllocationView(_ item: PendingCareGapAllocation) -> PendingCareGapAllocationView {
        return PendingCareGapAllocationView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            procedureCode: item.procedureCode,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            endsAtText: String(item.endsAt),
            maximum: String(format: "%.2f", item.maximum),
            discountText: String(format: "%.2f", item.discount),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCareGapAllocationViews(_ items: [PendingCareGapAllocation]) -> [PendingCareGapAllocationView] {
        var views: [PendingCareGapAllocationView] = []
        for item in items {
            views.append(toPendingCareGapAllocationView(item))
        }
        return views
    }

    static func sumPendingCareGapAllocationView(_ view: PendingCareGapAllocationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedEndsAt) + parsedMaximum + parsedDiscount
    }
}
