import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility assignment is in its life cycle.
    enum FallbackEligibilityAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback eligibility assignment, with what the planners need to act on it.
    final class FallbackEligibilityAssignment {
        var code: String
        var title: String
        var copay: Double
        var facility: String
        var durationMinutes: Int
        var maximum: Double
        var name: String
        var createdAt: Int
        var visitMinutes: Int
        var discount: Double
        var timezone: String
        var status: FallbackEligibilityAssignmentStatus

        init(code: String, title: String, copay: Double, facility: String, durationMinutes: Int, maximum: Double, name: String, createdAt: Int, visitMinutes: Int, discount: Double, timezone: String, status: FallbackEligibilityAssignmentStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.name = name
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.discount = discount
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackEligibilityAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackEligibilityAssignmentStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: FallbackEligibilityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((Double(durationMinutes) + discount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackEligibilityAssignment {
            return FallbackEligibilityAssignment(
                code: code,
                title: title,
                copay: copay,
                facility: facility,
                durationMinutes: durationMinutes,
                maximum: maximum,
                name: name,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                discount: discount,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback eligibility assignment in status new.
    static func newFallbackEligibilityAssignment(_ code: String, title: String) -> FallbackEligibilityAssignment {
        return FallbackEligibilityAssignment(
            code: code,
            title: title,
            copay: 0.0,
            facility: "",
            durationMinutes: 0,
            maximum: 0.0,
            name: "",
            createdAt: 0,
            visitMinutes: 0,
            discount: 0.0,
            timezone: "",
            status: FallbackEligibilityAssignmentStatus.new
        )
    }
}
