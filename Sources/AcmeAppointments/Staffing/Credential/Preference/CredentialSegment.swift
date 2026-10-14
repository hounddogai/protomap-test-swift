import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential segment is in its life cycle.
    enum CredentialSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One credential segment, with what the planners need to act on it.
    final class CredentialSegment {
        var code: String
        var label: String
        var createdAt: Int
        var limit: Int
        var acuity: Int
        var diagnosisCode: String
        var country: String
        var status: CredentialSegmentStatus

        init(code: String, label: String, createdAt: Int, limit: Int, acuity: Int, diagnosisCode: String, country: String, status: CredentialSegmentStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.limit = limit
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.country = country
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

        func canMoveTo(_ next: CredentialSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CredentialSegmentStatus.approved || next == CredentialSegmentStatus.rejected
            case .approved:
                return next == CredentialSegmentStatus.withdrawn
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

        func moveTo(_ next: CredentialSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("credential segment") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(acuity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialSegment {
            return CredentialSegment(
                code: code,
                label: label,
                createdAt: createdAt,
                limit: limit,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a credential segment in status proposed.
    static func newCredentialSegment(_ code: String, label: String) -> CredentialSegment {
        return CredentialSegment(
            code: code,
            label: label,
            createdAt: 0,
            limit: 0,
            acuity: 0,
            diagnosisCode: "",
            country: "",
            status: CredentialSegmentStatus.proposed
        )
    }
}
