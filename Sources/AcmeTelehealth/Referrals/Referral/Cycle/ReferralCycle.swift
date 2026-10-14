import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral cycle is in its life cycle.
    enum ReferralCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a referral cycle and its current status.
    final class ReferralCycle {
        var code: String
        var name: String
        var reviewer: String
        var capacity: Int
        var label: String
        var attempts: Int
        var floorValue: Double
        var createdAt: Int
        var ceiling: Double
        var startsAt: Int
        var status: ReferralCycleStatus

        init(code: String, name: String, reviewer: String, capacity: Int, label: String, attempts: Int, floorValue: Double, createdAt: Int, ceiling: Double, startsAt: Int, status: ReferralCycleStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.capacity = capacity
            self.label = label
            self.attempts = attempts
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ReferralCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReferralCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return (ceiling * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ReferralCycle {
            return ReferralCycle(
                code: code,
                name: name,
                reviewer: reviewer,
                capacity: capacity,
                label: label,
                attempts: attempts,
                floorValue: floorValue,
                createdAt: createdAt,
                ceiling: ceiling,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral cycle in status proposed.
    static func newReferralCycle(_ code: String, name: String) -> ReferralCycle {
        return ReferralCycle(
            code: code,
            name: name,
            reviewer: "",
            capacity: 0,
            label: "",
            attempts: 0,
            floorValue: 0.0,
            createdAt: 0,
            ceiling: 0.0,
            startsAt: 0,
            status: ReferralCycleStatus.proposed
        )
    }
}
