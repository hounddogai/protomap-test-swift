import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation exception is in its life cycle.
    enum IsolationExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A isolation exception. Its code is unique within a tenant.
    final class IsolationException {
        var code: String
        var title: String
        var graceDays: Int
        var procedureCode: String
        var timezone: String
        var budget: Double
        var phone: String
        var retries: Int
        var tags: [String]
        var capacity: Int
        var status: IsolationExceptionStatus

        init(code: String, title: String, graceDays: Int, procedureCode: String, timezone: String, budget: Double, phone: String, retries: Int, tags: [String], capacity: Int, status: IsolationExceptionStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.timezone = timezone
            self.budget = budget
            self.phone = phone
            self.retries = retries
            self.tags = tags
            self.capacity = capacity
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

        func canMoveTo(_ next: IsolationExceptionStatus) -> Bool {
            switch status {
            case .requested:
                return next == IsolationExceptionStatus.revoked || next == IsolationExceptionStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == IsolationExceptionStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(capacity) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationException {
            return IsolationException(
                code: code,
                title: title,
                graceDays: graceDays,
                procedureCode: procedureCode,
                timezone: timezone,
                budget: budget,
                phone: phone,
                retries: retries,
                tags: tags,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation exception in status requested.
    static func newIsolationException(_ code: String, title: String) -> IsolationException {
        return IsolationException(
            code: code,
            title: title,
            graceDays: 0,
            procedureCode: "",
            timezone: "",
            budget: 0.0,
            phone: "",
            retries: 0,
            tags: [],
            capacity: 0,
            status: IsolationExceptionStatus.requested
        )
    }
}
