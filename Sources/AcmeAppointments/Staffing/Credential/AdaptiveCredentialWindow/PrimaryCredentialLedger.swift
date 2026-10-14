import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary credential ledger is in its life cycle.
    enum PrimaryCredentialLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary credential ledger as the credential team keeps it.
    final class PrimaryCredentialLedger {
        var code: String
        var name: String
        var attributes: [String: String]
        var weight: Double
        var maximum: Double
        var minimum: Double
        var status: PrimaryCredentialLedgerStatus

        init(code: String, name: String, attributes: [String: String], weight: Double, maximum: Double, minimum: Double, status: PrimaryCredentialLedgerStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.weight = weight
            self.maximum = maximum
            self.minimum = minimum
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

        func canMoveTo(_ next: PrimaryCredentialLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
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
                case .archived:
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

        func moveTo(_ next: PrimaryCredentialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary credential ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary credential ledger") \(code)"
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

        func effectiveLoad() -> Double {
            return ((minimum - weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCredentialLedger {
            return PrimaryCredentialLedger(
                code: code,
                name: name,
                attributes: attributes,
                weight: weight,
                maximum: maximum,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary credential ledger in status open.
    static func newPrimaryCredentialLedger(_ code: String, name: String) -> PrimaryCredentialLedger {
        return PrimaryCredentialLedger(
            code: code,
            name: name,
            attributes: [:],
            weight: 0.0,
            maximum: 0.0,
            minimum: 0.0,
            status: PrimaryCredentialLedgerStatus.`open`
        )
    }
}
