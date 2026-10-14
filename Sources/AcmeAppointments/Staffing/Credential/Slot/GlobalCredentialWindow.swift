import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global credential window is in its life cycle.
    enum GlobalCredentialWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One global credential window, with what the planners need to act on it.
    final class GlobalCredentialWindow {
        var code: String
        var label: String
        var contactEmail: String
        var payer: String
        var notes: String
        var retries: Int
        var country: String
        var encounterID: String
        var maximum: Double
        var unit: String
        var cost: Double
        var status: GlobalCredentialWindowStatus

        init(code: String, label: String, contactEmail: String, payer: String, notes: String, retries: Int, country: String, encounterID: String, maximum: Double, unit: String, cost: Double, status: GlobalCredentialWindowStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.payer = payer
            self.notes = notes
            self.retries = retries
            self.country = country
            self.encounterID = encounterID
            self.maximum = maximum
            self.unit = unit
            self.cost = cost
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

        func canMoveTo(_ next: GlobalCredentialWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GlobalCredentialWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCredentialWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global credential window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return (Double(retries) * maximum * 100).rounded() / 100
        }

        func copyValue() -> GlobalCredentialWindow {
            return GlobalCredentialWindow(
                code: code,
                label: label,
                contactEmail: contactEmail,
                payer: payer,
                notes: notes,
                retries: retries,
                country: country,
                encounterID: encounterID,
                maximum: maximum,
                unit: unit,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global credential window in status draft.
    static func newGlobalCredentialWindow(_ code: String, label: String) -> GlobalCredentialWindow {
        return GlobalCredentialWindow(
            code: code,
            label: label,
            contactEmail: "",
            payer: "",
            notes: "",
            retries: 0,
            country: "",
            encounterID: "",
            maximum: 0.0,
            unit: "",
            cost: 0.0,
            status: GlobalCredentialWindowStatus.draft
        )
    }
}
