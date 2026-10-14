import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default charge exception is in its life cycle.
    enum DefaultChargeExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default charge exception as the charge team keeps it.
    final class DefaultChargeException {
        var code: String
        var name: String
        var pinned: Bool
        var ownerID: String
        var timezone: String
        var sequence: Int
        var score: Double
        var diagnosisCode: String
        var status: DefaultChargeExceptionStatus

        init(code: String, name: String, pinned: Bool, ownerID: String, timezone: String, sequence: Int, score: Double, diagnosisCode: String, status: DefaultChargeExceptionStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.ownerID = ownerID
            self.timezone = timezone
            self.sequence = sequence
            self.score = score
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: DefaultChargeExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultChargeExceptionStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultChargeExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultChargeExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default charge exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((score + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultChargeException {
            return DefaultChargeException(
                code: code,
                name: name,
                pinned: pinned,
                ownerID: ownerID,
                timezone: timezone,
                sequence: sequence,
                score: score,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default charge exception in status proposed.
    static func newDefaultChargeException(_ code: String, name: String) -> DefaultChargeException {
        return DefaultChargeException(
            code: code,
            name: name,
            pinned: false,
            ownerID: "",
            timezone: "",
            sequence: 0,
            score: 0.0,
            diagnosisCode: "",
            status: DefaultChargeExceptionStatus.proposed
        )
    }
}
