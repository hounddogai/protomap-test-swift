import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy goal cycle is in its life cycle.
    enum LegacyGoalCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy goal cycle as the goal team keeps it.
    final class LegacyGoalCycle {
        var code: String
        var title: String
        var ward: String
        var floorValue: Double
        var score: Double
        var active: Bool
        var startsAt: Int
        var status: LegacyGoalCycleStatus

        init(code: String, title: String, ward: String, floorValue: Double, score: Double, active: Bool, startsAt: Int, status: LegacyGoalCycleStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.floorValue = floorValue
            self.score = score
            self.active = active
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

        func canMoveTo(_ next: LegacyGoalCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyGoalCycleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyGoalCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy goal cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((Double(startsAt) + score) * 100).rounded() / 100
        }

        func copyValue() -> LegacyGoalCycle {
            return LegacyGoalCycle(
                code: code,
                title: title,
                ward: ward,
                floorValue: floorValue,
                score: score,
                active: active,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy goal cycle in status proposed.
    static func newLegacyGoalCycle(_ code: String, title: String) -> LegacyGoalCycle {
        return LegacyGoalCycle(
            code: code,
            title: title,
            ward: "",
            floorValue: 0.0,
            score: 0.0,
            active: false,
            startsAt: 0,
            status: LegacyGoalCycleStatus.proposed
        )
    }
}
