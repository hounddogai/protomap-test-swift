import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled proxy batch is in its life cycle.
    enum ScheduledProxyBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled proxy batch, with what the planners need to act on it.
    final class ScheduledProxyBatch {
        var code: String
        var name: String
        var externalRef: String
        var country: String
        var label: String
        var budget: Double
        var ownerID: String
        var minimum: Double
        var contactEmail: String
        var status: ScheduledProxyBatchStatus

        init(code: String, name: String, externalRef: String, country: String, label: String, budget: Double, ownerID: String, minimum: Double, contactEmail: String, status: ScheduledProxyBatchStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.country = country
            self.label = label
            self.budget = budget
            self.ownerID = ownerID
            self.minimum = minimum
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ScheduledProxyBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ScheduledProxyBatchStatus.expired
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

        func moveTo(_ next: ScheduledProxyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled proxy batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled proxy batch") \(code)"
        }

        func projectedLoad() -> Double {
            return ((budget - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProxyBatch {
            return ScheduledProxyBatch(
                code: code,
                name: name,
                externalRef: externalRef,
                country: country,
                label: label,
                budget: budget,
                ownerID: ownerID,
                minimum: minimum,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a scheduled proxy batch in status requested.
    static func newScheduledProxyBatch(_ code: String, name: String) -> ScheduledProxyBatch {
        return ScheduledProxyBatch(
            code: code,
            name: name,
            externalRef: "",
            country: "",
            label: "",
            budget: 0.0,
            ownerID: "",
            minimum: 0.0,
            contactEmail: "",
            status: ScheduledProxyBatchStatus.requested
        )
    }
}
