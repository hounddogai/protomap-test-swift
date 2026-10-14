import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped denial target is in its life cycle.
    enum CappedDenialTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped denial target. Its code is unique within a tenant.
    final class CappedDenialTarget {
        var code: String
        var name: String
        var active: Bool
        var ceiling: Double
        var amount: Double
        var region: String
        var graceDays: Int
        var country: String
        var status: CappedDenialTargetStatus

        init(code: String, name: String, active: Bool, ceiling: Double, amount: Double, region: String, graceDays: Int, country: String, status: CappedDenialTargetStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.ceiling = ceiling
            self.amount = amount
            self.region = region
            self.graceDays = graceDays
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedDenialTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CappedDenialTargetStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CappedDenialTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDenialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped denial target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(graceDays) + amount) * 100).rounded() / 100
        }

        func copyValue() -> CappedDenialTarget {
            return CappedDenialTarget(
                code: code,
                name: name,
                active: active,
                ceiling: ceiling,
                amount: amount,
                region: region,
                graceDays: graceDays,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped denial target in status idle.
    static func newCappedDenialTarget(_ code: String, name: String) -> CappedDenialTarget {
        return CappedDenialTarget(
            code: code,
            name: name,
            active: false,
            ceiling: 0.0,
            amount: 0.0,
            region: "",
            graceDays: 0,
            country: "",
            status: CappedDenialTargetStatus.idle
        )
    }
}
