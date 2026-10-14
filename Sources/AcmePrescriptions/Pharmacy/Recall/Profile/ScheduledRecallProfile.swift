import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled recall profile is in its life cycle.
    enum ScheduledRecallProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled recall profile. Its code is unique within a tenant.
    final class ScheduledRecallProfile {
        var code: String
        var title: String
        var maximum: Double
        var amount: Double
        var createdAt: Int
        var diagnosisCode: String
        var graceDays: Int
        var status: ScheduledRecallProfileStatus

        init(code: String, title: String, maximum: Double, amount: Double, createdAt: Int, diagnosisCode: String, graceDays: Int, status: ScheduledRecallProfileStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.amount = amount
            self.createdAt = createdAt
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ScheduledRecallProfileStatus) -> Bool {
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
                return next == ScheduledRecallProfileStatus.rejected || next == ScheduledRecallProfileStatus.withdrawn
            case .rejected:
                return next == ScheduledRecallProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledRecallProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled recall profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled recall profile") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(graceDays) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRecallProfile {
            return ScheduledRecallProfile(
                code: code,
                title: title,
                maximum: maximum,
                amount: amount,
                createdAt: createdAt,
                diagnosisCode: diagnosisCode,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled recall profile in status proposed.
    static func newScheduledRecallProfile(_ code: String, title: String) -> ScheduledRecallProfile {
        return ScheduledRecallProfile(
            code: code,
            title: title,
            maximum: 0.0,
            amount: 0.0,
            createdAt: 0,
            diagnosisCode: "",
            graceDays: 0,
            status: ScheduledRecallProfileStatus.proposed
        )
    }
}
