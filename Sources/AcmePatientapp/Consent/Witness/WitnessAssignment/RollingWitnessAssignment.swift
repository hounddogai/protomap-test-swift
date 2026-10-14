import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling witness assignment is in its life cycle.
    enum RollingWitnessAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling witness assignment, with what the planners need to act on it.
    final class RollingWitnessAssignment {
        var code: String
        var title: String
        var diagnosisCode: String
        var quantity: Int
        var attempts: Int
        var locale: String
        var expiresAt: Int
        var batchSize: Int
        var phone: String
        var limit: Int
        var timezone: String
        var status: RollingWitnessAssignmentStatus

        init(code: String, title: String, diagnosisCode: String, quantity: Int, attempts: Int, locale: String, expiresAt: Int, batchSize: Int, phone: String, limit: Int, timezone: String, status: RollingWitnessAssignmentStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.attempts = attempts
            self.locale = locale
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.phone = phone
            self.limit = limit
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingWitnessAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingWitnessAssignmentStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingWitnessAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingWitnessAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling witness assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return (Double(quantity) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> RollingWitnessAssignment {
            return RollingWitnessAssignment(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                attempts: attempts,
                locale: locale,
                expiresAt: expiresAt,
                batchSize: batchSize,
                phone: phone,
                limit: limit,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling witness assignment in status created.
    static func newRollingWitnessAssignment(_ code: String, title: String) -> RollingWitnessAssignment {
        return RollingWitnessAssignment(
            code: code,
            title: title,
            diagnosisCode: "",
            quantity: 0,
            attempts: 0,
            locale: "",
            expiresAt: 0,
            batchSize: 0,
            phone: "",
            limit: 0,
            timezone: "",
            status: RollingWitnessAssignmentStatus.created
        )
    }
}
