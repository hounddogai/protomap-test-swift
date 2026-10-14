import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential segment.
    final class CredentialSegmentView {
        var code: String
        var label: String
        var createdAt: String
        var limit: String
        var acuity: String
        var diagnosisCode: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, limit: String, acuity: String, diagnosisCode: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.limit = limit
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialSegmentView(_ item: CredentialSegment) -> CredentialSegmentView {
        return CredentialSegmentView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            limit: String(item.limit),
            acuity: String(item.acuity),
            diagnosisCode: item.diagnosisCode,
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialSegmentViews(_ items: [CredentialSegment]) -> [CredentialSegmentView] {
        var views: [CredentialSegmentView] = []
        for item in items {
            views.append(toCredentialSegmentView(item))
        }
        return views
    }

    static func sumCredentialSegmentView(_ view: CredentialSegmentView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedLimit) + Double(parsedAcuity)
    }
}
