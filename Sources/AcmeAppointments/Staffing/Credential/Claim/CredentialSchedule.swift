import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential schedule is in its life cycle.
    enum CredentialScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A credential schedule. Its code is unique within a tenant.
    final class CredentialSchedule {
        var code: String
        var name: String
        var currency: String
        var priority: Int
        var discount: Double
        var reviewer: String
        var attributes: [String: String]
        var sequence: Int
        var phone: String
        var retries: Int
        var label: String
        var status: CredentialScheduleStatus

        init(code: String, name: String, currency: String, priority: Int, discount: Double, reviewer: String, attributes: [String: String], sequence: Int, phone: String, retries: Int, label: String, status: CredentialScheduleStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.priority = priority
            self.discount = discount
            self.reviewer = reviewer
            self.attributes = attributes
            self.sequence = sequence
            self.phone = phone
            self.retries = retries
            self.label = label
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

        func canMoveTo(_ next: CredentialScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CredentialScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("credential schedule") \(code)"
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

        func effectiveVolume() -> Double {
            return ((discount - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialSchedule {
            return CredentialSchedule(
                code: code,
                name: name,
                currency: currency,
                priority: priority,
                discount: discount,
                reviewer: reviewer,
                attributes: attributes,
                sequence: sequence,
                phone: phone,
                retries: retries,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a credential schedule in status proposed.
    static func newCredentialSchedule(_ code: String, name: String) -> CredentialSchedule {
        return CredentialSchedule(
            code: code,
            name: name,
            currency: "",
            priority: 0,
            discount: 0.0,
            reviewer: "",
            attributes: [:],
            sequence: 0,
            phone: "",
            retries: 0,
            label: "",
            status: CredentialScheduleStatus.proposed
        )
    }
}
