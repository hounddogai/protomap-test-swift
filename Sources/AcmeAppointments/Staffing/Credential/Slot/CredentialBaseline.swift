import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential baseline is in its life cycle.
    enum CredentialBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A credential baseline. Its code is unique within a tenant.
    final class CredentialBaseline {
        var code: String
        var title: String
        var notes: String
        var attributes: [String: String]
        var dosageMg: Double
        var endsAt: Int
        var patientRef: String
        var status: CredentialBaselineStatus

        init(code: String, title: String, notes: String, attributes: [String: String], dosageMg: Double, endsAt: Int, patientRef: String, status: CredentialBaselineStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CredentialBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == CredentialBaselineStatus.validated
            case .validated:
                return next == CredentialBaselineStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CredentialBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("credential baseline") \(code)"
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

        func netExposure() -> Double {
            return ((dosageMg - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialBaseline {
            return CredentialBaseline(
                code: code,
                title: title,
                notes: notes,
                attributes: attributes,
                dosageMg: dosageMg,
                endsAt: endsAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential baseline in status created.
    static func newCredentialBaseline(_ code: String, title: String) -> CredentialBaseline {
        return CredentialBaseline(
            code: code,
            title: title,
            notes: "",
            attributes: [:],
            dosageMg: 0.0,
            endsAt: 0,
            patientRef: "",
            status: CredentialBaselineStatus.created
        )
    }
}
