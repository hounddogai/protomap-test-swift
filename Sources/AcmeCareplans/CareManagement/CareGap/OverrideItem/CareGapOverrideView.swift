import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap override.
    final class CareGapOverrideView {
        var code: String
        var title: String
        var revision: String
        var procedureCode: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, revision: String, procedureCode: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.procedureCode = procedureCode
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapOverrideView(_ item: CareGapOverride) -> CareGapOverrideView {
        return CareGapOverrideView(
            code: item.code,
            title: item.title,
            revision: String(item.revision),
            procedureCode: item.procedureCode,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapOverrideViews(_ items: [CareGapOverride]) -> [CareGapOverrideView] {
        var views: [CareGapOverrideView] = []
        for item in items {
            views.append(toCareGapOverrideView(item))
        }
        return views
    }

    static func sumCareGapOverrideView(_ view: CareGapOverrideView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
