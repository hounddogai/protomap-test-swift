import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift agreement is in its life cycle.
    enum ShiftAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One shift agreement, with what the planners need to act on it.
    final class ShiftAgreement {
        var code: String
        var name: String
        var phone: String
        var timezone: String
        var label: String
        var contactEmail: String
        var ceiling: Double
        var ownerID: String
        var facility: String
        var attributes: [String: String]
        var status: ShiftAgreementStatus

        init(code: String, name: String, phone: String, timezone: String, label: String, contactEmail: String, ceiling: Double, ownerID: String, facility: String, attributes: [String: String], status: ShiftAgreementStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.timezone = timezone
            self.label = label
            self.contactEmail = contactEmail
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.facility = facility
            self.attributes = attributes
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

        func canMoveTo(_ next: ShiftAgreementStatus) -> Bool {
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

        func moveTo(_ next: ShiftAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
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

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ShiftAgreement {
            return ShiftAgreement(
                code: code,
                name: name,
                phone: phone,
                timezone: timezone,
                label: label,
                contactEmail: contactEmail,
                ceiling: ceiling,
                ownerID: ownerID,
                facility: facility,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a shift agreement in status requested.
    static func newShiftAgreement(_ code: String, name: String) -> ShiftAgreement {
        return ShiftAgreement(
            code: code,
            name: name,
            phone: "",
            timezone: "",
            label: "",
            contactEmail: "",
            ceiling: 0.0,
            ownerID: "",
            facility: "",
            attributes: [:],
            status: ShiftAgreementStatus.requested
        )
    }
}
