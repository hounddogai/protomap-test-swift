import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure request is in its life cycle.
    enum ClosureRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A closure request. Its code is unique within a tenant.
    final class ClosureRequest {
        var code: String
        var name: String
        var rate: Double
        var clinicianID: String
        var limit: Int
        var maximum: Double
        var status: ClosureRequestStatus

        init(code: String, name: String, rate: Double, clinicianID: String, limit: Int, maximum: Double, status: ClosureRequestStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.clinicianID = clinicianID
            self.limit = limit
            self.maximum = maximum
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

        func canMoveTo(_ next: ClosureRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ClosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((rate + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ClosureRequest {
            return ClosureRequest(
                code: code,
                name: name,
                rate: rate,
                clinicianID: clinicianID,
                limit: limit,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a closure request in status proposed.
    static func newClosureRequest(_ code: String, name: String) -> ClosureRequest {
        return ClosureRequest(
            code: code,
            name: name,
            rate: 0.0,
            clinicianID: "",
            limit: 0,
            maximum: 0.0,
            status: ClosureRequestStatus.proposed
        )
    }
}
