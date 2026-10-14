import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment claim is in its life cycle.
    enum AssessmentClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a assessment claim and its current status.
    final class AssessmentClaim {
        var code: String
        var label: String
        var attributes: [String: String]
        var acuity: Int
        var endsAt: Int
        var contactEmail: String
        var title: String
        var expiresAt: Int
        var margin: Double
        var status: AssessmentClaimStatus

        init(code: String, label: String, attributes: [String: String], acuity: Int, endsAt: Int, contactEmail: String, title: String, expiresAt: Int, margin: Double, status: AssessmentClaimStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.acuity = acuity
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.title = title
            self.expiresAt = expiresAt
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AssessmentClaimStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("assessment claim") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return ((Double(endsAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentClaim {
            return AssessmentClaim(
                code: code,
                label: label,
                attributes: attributes,
                acuity: acuity,
                endsAt: endsAt,
                contactEmail: contactEmail,
                title: title,
                expiresAt: expiresAt,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment claim in status proposed.
    static func newAssessmentClaim(_ code: String, label: String) -> AssessmentClaim {
        return AssessmentClaim(
            code: code,
            label: label,
            attributes: [:],
            acuity: 0,
            endsAt: 0,
            contactEmail: "",
            title: "",
            expiresAt: 0,
            margin: 0.0,
            status: AssessmentClaimStatus.proposed
        )
    }
}
