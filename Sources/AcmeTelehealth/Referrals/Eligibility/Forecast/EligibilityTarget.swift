import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility target is in its life cycle.
    enum EligibilityTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One eligibility target, with what the planners need to act on it.
    final class EligibilityTarget {
        var code: String
        var name: String
        var minimum: Double
        var cost: Double
        var durationMinutes: Int
        var endsAt: Int
        var ward: String
        var title: String
        var ratio: Double
        var country: String
        var status: EligibilityTargetStatus

        init(code: String, name: String, minimum: Double, cost: Double, durationMinutes: Int, endsAt: Int, ward: String, title: String, ratio: Double, country: String, status: EligibilityTargetStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.cost = cost
            self.durationMinutes = durationMinutes
            self.endsAt = endsAt
            self.ward = ward
            self.title = title
            self.ratio = ratio
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == EligibilityTargetStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: EligibilityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((Double(durationMinutes) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityTarget {
            return EligibilityTarget(
                code: code,
                name: name,
                minimum: minimum,
                cost: cost,
                durationMinutes: durationMinutes,
                endsAt: endsAt,
                ward: ward,
                title: title,
                ratio: ratio,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a eligibility target in status planned.
    static func newEligibilityTarget(_ code: String, name: String) -> EligibilityTarget {
        return EligibilityTarget(
            code: code,
            name: name,
            minimum: 0.0,
            cost: 0.0,
            durationMinutes: 0,
            endsAt: 0,
            ward: "",
            title: "",
            ratio: 0.0,
            country: "",
            status: EligibilityTargetStatus.planned
        )
    }
}
