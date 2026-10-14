import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot rule is in its life cycle.
    enum SlotRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a slot rule and its current status.
    final class SlotRule {
        var code: String
        var label: String
        var active: Bool
        var startsAt: Int
        var dosageMg: Double
        var status: SlotRuleStatus

        init(code: String, label: String, active: Bool, startsAt: Int, dosageMg: Double, status: SlotRuleStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.startsAt = startsAt
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: SlotRuleStatus) -> Bool {
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
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SlotRuleStatus.draining
            case .draining:
                return next == SlotRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((dosageMg - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SlotRule {
            return SlotRule(
                code: code,
                label: label,
                active: active,
                startsAt: startsAt,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a slot rule in status idle.
    static func newSlotRule(_ code: String, label: String) -> SlotRule {
        return SlotRule(
            code: code,
            label: label,
            active: false,
            startsAt: 0,
            dosageMg: 0.0,
            status: SlotRuleStatus.idle
        )
    }
}
