import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending transfer draft.
    final class PendingTransferDraftView {
        var code: String
        var label: String
        var windowDays: String
        var patientRef: String
        var pinned: String
        var priority: String
        var weight: String
        var statusLabel: String

        init(code: String, label: String, windowDays: String, patientRef: String, pinned: String, priority: String, weight: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.patientRef = patientRef
            self.pinned = pinned
            self.priority = priority
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toPendingTransferDraftView(_ item: PendingTransferDraft) -> PendingTransferDraftView {
        return PendingTransferDraftView(
            code: item.code,
            label: item.label,
            windowDays: String(item.windowDays),
            patientRef: item.patientRef,
            pinned: "\(item.pinned)",
            priority: String(item.priority),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingTransferDraftViews(_ items: [PendingTransferDraft]) -> [PendingTransferDraftView] {
        var views: [PendingTransferDraftView] = []
        for item in items {
            views.append(toPendingTransferDraftView(item))
        }
        return views
    }

    static func sumPendingTransferDraftView(_ view: PendingTransferDraftView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedPriority) + parsedWeight
    }
}
