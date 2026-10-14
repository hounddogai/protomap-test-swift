import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default program override is in its life cycle.
    enum DefaultProgramOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default program override, with what the planners need to act on it.
    final class DefaultProgramOverride {
        var code: String
        var label: String
        var timezone: String
        var procedureCode: String
        var endsAt: Int
        var attributes: [String: String]
        var externalRef: String
        var phone: String
        var status: DefaultProgramOverrideStatus

        init(code: String, label: String, timezone: String, procedureCode: String, endsAt: Int, attributes: [String: String], externalRef: String, phone: String, status: DefaultProgramOverrideStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.attributes = attributes
            self.externalRef = externalRef
            self.phone = phone
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

        func canMoveTo(_ next: DefaultProgramOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultProgramOverrideStatus.granted || next == DefaultProgramOverrideStatus.revoked
            case .granted:
                return next == DefaultProgramOverrideStatus.revoked || next == DefaultProgramOverrideStatus.expired
            case .revoked:
                return next == DefaultProgramOverrideStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultProgramOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default program override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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
            return Double(endsAt)
        }

        func copyValue() -> DefaultProgramOverride {
            return DefaultProgramOverride(
                code: code,
                label: label,
                timezone: timezone,
                procedureCode: procedureCode,
                endsAt: endsAt,
                attributes: attributes,
                externalRef: externalRef,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default program override in status requested.
    static func newDefaultProgramOverride(_ code: String, label: String) -> DefaultProgramOverride {
        return DefaultProgramOverride(
            code: code,
            label: label,
            timezone: "",
            procedureCode: "",
            endsAt: 0,
            attributes: [:],
            externalRef: "",
            phone: "",
            status: DefaultProgramOverrideStatus.requested
        )
    }
}
