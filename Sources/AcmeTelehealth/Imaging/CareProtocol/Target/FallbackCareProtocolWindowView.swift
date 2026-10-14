import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback care protocol window.
    final class FallbackCareProtocolWindowView {
        var code: String
        var title: String
        var discount: String
        var dosageMg: String
        var createdAt: String
        var copay: String
        var active: String
        var notesText: String
        var bed: String
        var specialtyText: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, discount: String, dosageMg: String, createdAt: String, copay: String, active: String, notesText: String, bed: String, specialtyText: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discount = discount
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.copay = copay
            self.active = active
            self.notesText = notesText
            self.bed = bed
            self.specialtyText = specialtyText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolWindowView(_ item: FallbackCareProtocolWindow) -> FallbackCareProtocolWindowView {
        return FallbackCareProtocolWindowView(
            code: item.code,
            title: item.title,
            discount: String(format: "%.2f", item.discount),
            dosageMg: String(format: "%.2f", item.dosageMg),
            createdAt: String(item.createdAt),
            copay: String(format: "%.2f", item.copay),
            active: "\(item.active)",
            notesText: Kit.Text.truncate(item.notes, limit: 120),
            bed: item.bed,
            specialtyText: item.specialty,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolWindowViews(_ items: [FallbackCareProtocolWindow]) -> [FallbackCareProtocolWindowView] {
        var views: [FallbackCareProtocolWindowView] = []
        for item in items {
            views.append(toFallbackCareProtocolWindowView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolWindowView(_ view: FallbackCareProtocolWindowView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + parsedDosageMg + Double(parsedCreatedAt)
    }
}
