import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback isolation group.
    final class FallbackIsolationGroupView {
        var code: String
        var label: String
        var specialty: String
        var expiresAt: String
        var quantityText: String
        var endsAt: String
        var notesText: String
        var activeText: String
        var maximum: String
        var visitMinutes: String
        var segmentText: String
        var statusLabel: String

        init(code: String, label: String, specialty: String, expiresAt: String, quantityText: String, endsAt: String, notesText: String, activeText: String, maximum: String, visitMinutes: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.quantityText = quantityText
            self.endsAt = endsAt
            self.notesText = notesText
            self.activeText = activeText
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackIsolationGroupView(_ item: FallbackIsolationGroup) -> FallbackIsolationGroupView {
        return FallbackIsolationGroupView(
            code: item.code,
            label: item.label,
            specialty: item.specialty,
            expiresAt: String(item.expiresAt),
            quantityText: String(item.quantity),
            endsAt: String(item.endsAt),
            notesText: item.notes,
            activeText: "\(item.active)",
            maximum: String(format: "%.2f", item.maximum),
            visitMinutes: String(item.visitMinutes),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackIsolationGroupViews(_ items: [FallbackIsolationGroup]) -> [FallbackIsolationGroupView] {
        var views: [FallbackIsolationGroupView] = []
        for item in items {
            views.append(toFallbackIsolationGroupView(item))
        }
        return views
    }

    static func sumFallbackIsolationGroupView(_ view: FallbackIsolationGroupView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedQuantity) + Double(parsedEndsAt)
    }
}
