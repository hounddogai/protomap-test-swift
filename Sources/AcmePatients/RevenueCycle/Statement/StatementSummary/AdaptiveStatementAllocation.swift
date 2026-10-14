import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement allocation is in its life cycle.
    enum AdaptiveStatementAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive statement allocation as the statement team keeps it.
    final class AdaptiveStatementAllocation {
        var code: String
        var title: String
        var threshold: Double
        var active: Bool
        var durationMinutes: Int
        var endsAt: Int
        var status: AdaptiveStatementAllocationStatus

        init(code: String, title: String, threshold: Double, active: Bool, durationMinutes: Int, endsAt: Int, status: AdaptiveStatementAllocationStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.active = active
            self.durationMinutes = durationMinutes
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AdaptiveStatementAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveStatementAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive statement allocation") \(code)"
        }

        func netVolume() -> Double {
            return ((threshold - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStatementAllocation {
            return AdaptiveStatementAllocation(
                code: code,
                title: title,
                threshold: threshold,
                active: active,
                durationMinutes: durationMinutes,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive statement allocation in status proposed.
    static func newAdaptiveStatementAllocation(_ code: String, title: String) -> AdaptiveStatementAllocation {
        return AdaptiveStatementAllocation(
            code: code,
            title: title,
            threshold: 0.0,
            active: false,
            durationMinutes: 0,
            endsAt: 0,
            status: AdaptiveStatementAllocationStatus.proposed
        )
    }
}
