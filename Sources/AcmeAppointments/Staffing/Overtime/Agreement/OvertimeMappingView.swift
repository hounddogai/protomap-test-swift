import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime mapping.
    final class OvertimeMappingView {
        var code: String
        var titleText: String
        var sequence: String
        var procedureCode: String
        var copay: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, titleText: String, sequence: String, procedureCode: String, copay: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.copay = copay
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeMappingView(_ item: OvertimeMapping) -> OvertimeMappingView {
        return OvertimeMappingView(
            code: item.code,
            titleText: item.title,
            sequence: String(item.sequence),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            copay: String(format: "%.2f", item.copay),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeMappingViews(_ items: [OvertimeMapping]) -> [OvertimeMappingView] {
        var views: [OvertimeMappingView] = []
        for item in items {
            views.append(toOvertimeMappingView(item))
        }
        return views
    }

    static func sumOvertimeMappingView(_ view: OvertimeMappingView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedSequence) + parsedCopay + Double(parsedUpdatedAt)
    }
}
