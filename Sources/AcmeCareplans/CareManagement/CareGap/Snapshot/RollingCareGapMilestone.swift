import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling care gap milestone is in its life cycle.
    enum RollingCareGapMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling care gap milestone as the care gap team keeps it.
    final class RollingCareGapMilestone {
        var code: String
        var title: String
        var priority: Int
        var attributes: [String: String]
        var ward: String
        var weight: Double
        var status: RollingCareGapMilestoneStatus

        init(code: String, title: String, priority: Int, attributes: [String: String], ward: String, weight: Double, status: RollingCareGapMilestoneStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.attributes = attributes
            self.ward = ward
            self.weight = weight
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

        func canMoveTo(_ next: RollingCareGapMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingCareGapMilestoneStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingCareGapMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareGapMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care gap milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveValue() -> Double {
            return ((weight + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareGapMilestone {
            return RollingCareGapMilestone(
                code: code,
                title: title,
                priority: priority,
                attributes: attributes,
                ward: ward,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling care gap milestone in status idle.
    static func newRollingCareGapMilestone(_ code: String, title: String) -> RollingCareGapMilestone {
        return RollingCareGapMilestone(
            code: code,
            title: title,
            priority: 0,
            attributes: [:],
            ward: "",
            weight: 0.0,
            status: RollingCareGapMilestoneStatus.idle
        )
    }
}
