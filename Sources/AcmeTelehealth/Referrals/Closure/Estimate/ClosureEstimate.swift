import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure estimate is in its life cycle.
    enum ClosureEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a closure estimate and its current status.
    final class ClosureEstimate {
        var code: String
        var name: String
        var windowDays: Int
        var capacity: Int
        var currency: String
        var status: ClosureEstimateStatus

        init(code: String, name: String, windowDays: Int, capacity: Int, currency: String, status: ClosureEstimateStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.capacity = capacity
            self.currency = currency
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

        func canMoveTo(_ next: ClosureEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ClosureEstimateStatus.revoked || next == ClosureEstimateStatus.expired
            case .revoked:
                return next == ClosureEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedExposure() -> Double {
            return ((Double(windowDays) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureEstimate {
            return ClosureEstimate(
                code: code,
                name: name,
                windowDays: windowDays,
                capacity: capacity,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a closure estimate in status requested.
    static func newClosureEstimate(_ code: String, name: String) -> ClosureEstimate {
        return ClosureEstimate(
            code: code,
            name: name,
            windowDays: 0,
            capacity: 0,
            currency: "",
            status: ClosureEstimateStatus.requested
        )
    }
}
