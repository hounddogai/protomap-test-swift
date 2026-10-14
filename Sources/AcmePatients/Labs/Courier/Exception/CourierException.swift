import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier exception is in its life cycle.
    enum CourierExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A courier exception as the courier team keeps it.
    final class CourierException {
        var code: String
        var title: String
        var createdAt: Int
        var acuity: Int
        var version: Int
        var status: CourierExceptionStatus

        init(code: String, title: String, createdAt: Int, acuity: Int, version: Int, status: CourierExceptionStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.acuity = acuity
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierExceptionStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CourierExceptionStatus.closed
            case .suspended:
                return next == CourierExceptionStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netTotal() -> Double {
            return ((Double(version) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CourierException {
            return CourierException(
                code: code,
                title: title,
                createdAt: createdAt,
                acuity: acuity,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a courier exception in status draft.
    static func newCourierException(_ code: String, title: String) -> CourierException {
        return CourierException(
            code: code,
            title: title,
            createdAt: 0,
            acuity: 0,
            version: 0,
            status: CourierExceptionStatus.draft
        )
    }
}
