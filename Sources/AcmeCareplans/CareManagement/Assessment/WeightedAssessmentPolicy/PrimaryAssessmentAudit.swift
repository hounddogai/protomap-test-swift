import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary assessment audit is in its life cycle.
    enum PrimaryAssessmentAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary assessment audit and its current status.
    final class PrimaryAssessmentAudit {
        var code: String
        var name: String
        var retries: Int
        var facility: String
        var priority: Int
        var payer: String
        var summary: String
        var maximum: Double
        var country: String
        var status: PrimaryAssessmentAuditStatus

        init(code: String, name: String, retries: Int, facility: String, priority: Int, payer: String, summary: String, maximum: Double, country: String, status: PrimaryAssessmentAuditStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.facility = facility
            self.priority = priority
            self.payer = payer
            self.summary = summary
            self.maximum = maximum
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryAssessmentAuditStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryAssessmentAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary assessment audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((maximum - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAssessmentAudit {
            return PrimaryAssessmentAudit(
                code: code,
                name: name,
                retries: retries,
                facility: facility,
                priority: priority,
                payer: payer,
                summary: summary,
                maximum: maximum,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary assessment audit in status requested.
    static func newPrimaryAssessmentAudit(_ code: String, name: String) -> PrimaryAssessmentAudit {
        return PrimaryAssessmentAudit(
            code: code,
            name: name,
            retries: 0,
            facility: "",
            priority: 0,
            payer: "",
            summary: "",
            maximum: 0.0,
            country: "",
            status: PrimaryAssessmentAuditStatus.requested
        )
    }
}
