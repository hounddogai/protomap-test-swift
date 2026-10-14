import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched specimen policy is in its life cycle.
    enum BatchedSpecimenPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched specimen policy, with what the planners need to act on it.
    final class BatchedSpecimenPolicy {
        var code: String
        var name: String
        var country: String
        var updatedAt: Int
        var patientRef: String
        var windowDays: Int
        var graceDays: Int
        var status: BatchedSpecimenPolicyStatus

        init(code: String, name: String, country: String, updatedAt: Int, patientRef: String, windowDays: Int, graceDays: Int, status: BatchedSpecimenPolicyStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.graceDays = graceDays
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

        func canMoveTo(_ next: BatchedSpecimenPolicyStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedSpecimenPolicyStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSpecimenPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched specimen policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched specimen policy") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(windowDays) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSpecimenPolicy {
            return BatchedSpecimenPolicy(
                code: code,
                name: name,
                country: country,
                updatedAt: updatedAt,
                patientRef: patientRef,
                windowDays: windowDays,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched specimen policy in status requested.
    static func newBatchedSpecimenPolicy(_ code: String, name: String) -> BatchedSpecimenPolicy {
        return BatchedSpecimenPolicy(
            code: code,
            name: name,
            country: "",
            updatedAt: 0,
            patientRef: "",
            windowDays: 0,
            graceDays: 0,
            status: BatchedSpecimenPolicyStatus.requested
        )
    }
}
