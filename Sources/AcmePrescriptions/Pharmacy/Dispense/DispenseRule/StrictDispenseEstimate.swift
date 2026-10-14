import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict dispense estimate is in its life cycle.
    enum StrictDispenseEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict dispense estimate and its current status.
    final class StrictDispenseEstimate {
        var code: String
        var name: String
        var expiresAt: Int
        var graceDays: Int
        var createdAt: Int
        var status: StrictDispenseEstimateStatus

        init(code: String, name: String, expiresAt: Int, graceDays: Int, createdAt: Int, status: StrictDispenseEstimateStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.graceDays = graceDays
            self.createdAt = createdAt
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

        func canMoveTo(_ next: StrictDispenseEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictDispenseEstimateStatus.approved || next == StrictDispenseEstimateStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: StrictDispenseEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict dispense estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict dispense estimate") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(graceDays) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictDispenseEstimate {
            return StrictDispenseEstimate(
                code: code,
                name: name,
                expiresAt: expiresAt,
                graceDays: graceDays,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict dispense estimate in status proposed.
    static func newStrictDispenseEstimate(_ code: String, name: String) -> StrictDispenseEstimate {
        return StrictDispenseEstimate(
            code: code,
            name: name,
            expiresAt: 0,
            graceDays: 0,
            createdAt: 0,
            status: StrictDispenseEstimateStatus.proposed
        )
    }
}
