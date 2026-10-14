import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling reference range request.
    final class RollingReferenceRangeRequestView {
        var codeText: String
        var label: String
        var description: String
        var acuity: String
        var activeText: String
        var statusLabel: String

        init(codeText: String, label: String, description: String, acuity: String, activeText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.description = description
            self.acuity = acuity
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingReferenceRangeRequestView(_ item: RollingReferenceRangeRequest) -> RollingReferenceRangeRequestView {
        return RollingReferenceRangeRequestView(
            codeText: item.code,
            label: item.label,
            description: item.description,
            acuity: String(item.acuity),
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingReferenceRangeRequestViews(_ items: [RollingReferenceRangeRequest]) -> [RollingReferenceRangeRequestView] {
        var views: [RollingReferenceRangeRequestView] = []
        for item in items {
            views.append(toRollingReferenceRangeRequestView(item))
        }
        return views
    }

    static func sumRollingReferenceRangeRequestView(_ view: RollingReferenceRangeRequestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
