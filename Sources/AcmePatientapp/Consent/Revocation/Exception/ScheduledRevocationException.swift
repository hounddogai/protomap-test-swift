import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation exception is in its life cycle.
    enum ScheduledRevocationExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled revocation exception, with what the planners need to act on it.
    final class ScheduledRevocationException {
        var code: String
        var name: String
        var category: String
        var ceiling: Double
        var segment: String
        var allergy: String
        var status: ScheduledRevocationExceptionStatus

        init(code: String, name: String, category: String, ceiling: Double, segment: String, allergy: String, status: ScheduledRevocationExceptionStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.ceiling = ceiling
            self.segment = segment
            self.allergy = allergy
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

        func canMoveTo(_ next: ScheduledRevocationExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ScheduledRevocationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled revocation exception") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ScheduledRevocationException {
            return ScheduledRevocationException(
                code: code,
                name: name,
                category: category,
                ceiling: ceiling,
                segment: segment,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled revocation exception in status requested.
    static func newScheduledRevocationException(_ code: String, name: String) -> ScheduledRevocationException {
        return ScheduledRevocationException(
            code: code,
            name: name,
            category: "",
            ceiling: 0.0,
            segment: "",
            allergy: "",
            status: ScheduledRevocationExceptionStatus.requested
        )
    }
}
