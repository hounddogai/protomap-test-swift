import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual handoff assignment.
    final class ManualHandoffAssignmentView {
        var code: String
        var name: String
        var visible: String
        var channelText: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, name: String, visible: String, channelText: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visible = visible
            self.channelText = channelText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toManualHandoffAssignmentView(_ item: ManualHandoffAssignment) -> ManualHandoffAssignmentView {
        return ManualHandoffAssignmentView(
            code: item.code,
            name: item.name,
            visible: "\(item.visible)",
            channelText: item.channel,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualHandoffAssignmentViews(_ items: [ManualHandoffAssignment]) -> [ManualHandoffAssignmentView] {
        var views: [ManualHandoffAssignmentView] = []
        for item in items {
            views.append(toManualHandoffAssignmentView(item))
        }
        return views
    }

    static func sumManualHandoffAssignmentView(_ view: ManualHandoffAssignmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
