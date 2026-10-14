import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task exception is in its life cycle.
    enum TaskExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One task exception, with what the planners need to act on it.
    final class TaskException {
        var code: String
        var title: String
        var acuity: Int
        var endsAt: Int
        var currency: String
        var ratio: Double
        var status: TaskExceptionStatus

        init(code: String, title: String, acuity: Int, endsAt: Int, currency: String, ratio: Double, status: TaskExceptionStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.endsAt = endsAt
            self.currency = currency
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TaskExceptionStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return (Double(acuity) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> TaskException {
            return TaskException(
                code: code,
                title: title,
                acuity: acuity,
                endsAt: endsAt,
                currency: currency,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task exception in status requested.
    static func newTaskException(_ code: String, title: String) -> TaskException {
        return TaskException(
            code: code,
            title: title,
            acuity: 0,
            endsAt: 0,
            currency: "",
            ratio: 0.0,
            status: TaskExceptionStatus.requested
        )
    }
}
