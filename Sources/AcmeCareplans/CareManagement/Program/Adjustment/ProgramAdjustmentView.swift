import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program adjustment.
    final class ProgramAdjustmentView {
        var code: String
        var label: String
        var category: String
        var pinned: String
        var acuity: String
        var statusLabel: String

        init(code: String, label: String, category: String, pinned: String, acuity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.category = category
            self.pinned = pinned
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toProgramAdjustmentView(_ item: ProgramAdjustment) -> ProgramAdjustmentView {
        return ProgramAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            category: Kit.Text.truncate(item.category, limit: 80),
            pinned: "\(item.pinned)",
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramAdjustmentViews(_ items: [ProgramAdjustment]) -> [ProgramAdjustmentView] {
        var views: [ProgramAdjustmentView] = []
        for item in items {
            views.append(toProgramAdjustmentView(item))
        }
        return views
    }

    static func sumProgramAdjustmentView(_ view: ProgramAdjustmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
