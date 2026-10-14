import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending formulary allocation.
    final class PendingFormularyAllocationView {
        var codeText: String
        var title: String
        var bedText: String
        var pinnedText: String
        var clinicianID: String
        var active: String
        var margin: String
        var statusLabel: String

        init(codeText: String, title: String, bedText: String, pinnedText: String, clinicianID: String, active: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.bedText = bedText
            self.pinnedText = pinnedText
            self.clinicianID = clinicianID
            self.active = active
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFormularyAllocationView(_ item: PendingFormularyAllocation) -> PendingFormularyAllocationView {
        return PendingFormularyAllocationView(
            codeText: item.code,
            title: item.title,
            bedText: item.bed,
            pinnedText: "\(item.pinned)",
            clinicianID: item.clinicianID,
            active: "\(item.active)",
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFormularyAllocationViews(_ items: [PendingFormularyAllocation]) -> [PendingFormularyAllocationView] {
        var views: [PendingFormularyAllocationView] = []
        for item in items {
            views.append(toPendingFormularyAllocationView(item))
        }
        return views
    }

    static func sumPendingFormularyAllocationView(_ view: PendingFormularyAllocationView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
