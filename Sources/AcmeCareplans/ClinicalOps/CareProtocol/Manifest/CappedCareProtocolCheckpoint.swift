import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped care protocol checkpoint is in its life cycle.
    enum CappedCareProtocolCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped care protocol checkpoint. Its code is unique within a tenant.
    final class CappedCareProtocolCheckpoint {
        var code: String
        var title: String
        var clinicianID: String
        var attempts: Int
        var phone: String
        var retries: Int
        var weight: Double
        var country: String
        var status: CappedCareProtocolCheckpointStatus

        init(code: String, title: String, clinicianID: String, attempts: Int, phone: String, retries: Int, weight: Double, country: String, status: CappedCareProtocolCheckpointStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.attempts = attempts
            self.phone = phone
            self.retries = retries
            self.weight = weight
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCareProtocolCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CappedCareProtocolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((weight - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareProtocolCheckpoint {
            return CappedCareProtocolCheckpoint(
                code: code,
                title: title,
                clinicianID: clinicianID,
                attempts: attempts,
                phone: phone,
                retries: retries,
                weight: weight,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped care protocol checkpoint in status open.
    static func newCappedCareProtocolCheckpoint(_ code: String, title: String) -> CappedCareProtocolCheckpoint {
        return CappedCareProtocolCheckpoint(
            code: code,
            title: title,
            clinicianID: "",
            attempts: 0,
            phone: "",
            retries: 0,
            weight: 0.0,
            country: "",
            status: CappedCareProtocolCheckpointStatus.`open`
        )
    }
}
