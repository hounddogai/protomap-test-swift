import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge segment is in its life cycle.
    enum ChargeSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One charge segment, with what the planners need to act on it.
    final class ChargeSegment {
        var code: String
        var name: String
        var reviewer: String
        var windowDays: Int
        var cost: Double
        var limit: Int
        var status: ChargeSegmentStatus

        init(code: String, name: String, reviewer: String, windowDays: Int, cost: Double, limit: Int, status: ChargeSegmentStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.windowDays = windowDays
            self.cost = cost
            self.limit = limit
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

        func canMoveTo(_ next: ChargeSegmentStatus) -> Bool {
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
                return next == ChargeSegmentStatus.expired
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

        func moveTo(_ next: ChargeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return (cost * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> ChargeSegment {
            return ChargeSegment(
                code: code,
                name: name,
                reviewer: reviewer,
                windowDays: windowDays,
                cost: cost,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge segment in status requested.
    static func newChargeSegment(_ code: String, name: String) -> ChargeSegment {
        return ChargeSegment(
            code: code,
            name: name,
            reviewer: "",
            windowDays: 0,
            cost: 0.0,
            limit: 0,
            status: ChargeSegmentStatus.requested
        )
    }
}
