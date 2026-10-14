import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient overtime assignment.
    final class LenientOvertimeAssignmentView {
        var code: String
        var title: String
        var marginText: String
        var refills: String
        var acuity: String
        var weight: String
        var statusLabel: String

        init(code: String, title: String, marginText: String, refills: String, acuity: String, weight: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.marginText = marginText
            self.refills = refills
            self.acuity = acuity
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOvertimeAssignmentView(_ item: LenientOvertimeAssignment) -> LenientOvertimeAssignmentView {
        return LenientOvertimeAssignmentView(
            code: item.code,
            title: item.title,
            marginText: String(format: "%.2f", item.margin),
            refills: String(item.refills),
            acuity: String(item.acuity),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOvertimeAssignmentViews(_ items: [LenientOvertimeAssignment]) -> [LenientOvertimeAssignmentView] {
        var views: [LenientOvertimeAssignmentView] = []
        for item in items {
            views.append(toLenientOvertimeAssignmentView(item))
        }
        return views
    }

    static func sumLenientOvertimeAssignmentView(_ view: LenientOvertimeAssignmentView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMargin + Double(parsedRefills) + Double(parsedAcuity)
    }
}
