import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure cycle is in its life cycle.
    enum ClosureCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a closure cycle and its current status.
    final class ClosureCycle {
        var code: String
        var label: String
        var ceiling: Double
        var amount: Double
        var region: String
        var ward: String
        var durationMinutes: Int
        var endsAt: Int
        var reviewer: String
        var graceDays: Int
        var status: ClosureCycleStatus

        init(code: String, label: String, ceiling: Double, amount: Double, region: String, ward: String, durationMinutes: Int, endsAt: Int, reviewer: String, graceDays: Int, status: ClosureCycleStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.amount = amount
            self.region = region
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ClosureCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == ClosureCycleStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ClosureCycleStatus.draining || next == ClosureCycleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ClosureCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureCycle {
            return ClosureCycle(
                code: code,
                label: label,
                ceiling: ceiling,
                amount: amount,
                region: region,
                ward: ward,
                durationMinutes: durationMinutes,
                endsAt: endsAt,
                reviewer: reviewer,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a closure cycle in status idle.
    static func newClosureCycle(_ code: String, label: String) -> ClosureCycle {
        return ClosureCycle(
            code: code,
            label: label,
            ceiling: 0.0,
            amount: 0.0,
            region: "",
            ward: "",
            durationMinutes: 0,
            endsAt: 0,
            reviewer: "",
            graceDays: 0,
            status: ClosureCycleStatus.idle
        )
    }
}
