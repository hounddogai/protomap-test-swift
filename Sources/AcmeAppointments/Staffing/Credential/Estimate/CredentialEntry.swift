import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential entry is in its life cycle.
    enum CredentialEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential entry as the credential team keeps it.
    final class CredentialEntry {
        var code: String
        var name: String
        var facility: String
        var bed: String
        var source: String
        var dosageMg: Double
        var status: CredentialEntryStatus

        init(code: String, name: String, facility: String, bed: String, source: String, dosageMg: Double, status: CredentialEntryStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.bed = bed
            self.source = source
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialEntryStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CredentialEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> CredentialEntry {
            return CredentialEntry(
                code: code,
                name: name,
                facility: facility,
                bed: bed,
                source: source,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential entry in status open.
    static func newCredentialEntry(_ code: String, name: String) -> CredentialEntry {
        return CredentialEntry(
            code: code,
            name: name,
            facility: "",
            bed: "",
            source: "",
            dosageMg: 0.0,
            status: CredentialEntryStatus.`open`
        )
    }
}
