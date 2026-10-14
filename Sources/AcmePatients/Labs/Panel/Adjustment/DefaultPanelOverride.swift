import AcmePlatform
import Foundation

extension Labs {
    /// Where a default panel override is in its life cycle.
    enum DefaultPanelOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default panel override as the panel team keeps it.
    final class DefaultPanelOverride {
        var code: String
        var name: String
        var threshold: Double
        var quantity: Int
        var ownerID: String
        var retries: Int
        var contactEmail: String
        var timezone: String
        var title: String
        var status: DefaultPanelOverrideStatus

        init(code: String, name: String, threshold: Double, quantity: Int, ownerID: String, retries: Int, contactEmail: String, timezone: String, title: String, status: DefaultPanelOverrideStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.quantity = quantity
            self.ownerID = ownerID
            self.retries = retries
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultPanelOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultPanelOverrideStatus.draining || next == DefaultPanelOverrideStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultPanelOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default panel override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default panel override") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(retries) * threshold * 100).rounded() / 100
        }

        func copyValue() -> DefaultPanelOverride {
            return DefaultPanelOverride(
                code: code,
                name: name,
                threshold: threshold,
                quantity: quantity,
                ownerID: ownerID,
                retries: retries,
                contactEmail: contactEmail,
                timezone: timezone,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default panel override in status idle.
    static func newDefaultPanelOverride(_ code: String, name: String) -> DefaultPanelOverride {
        return DefaultPanelOverride(
            code: code,
            name: name,
            threshold: 0.0,
            quantity: 0,
            ownerID: "",
            retries: 0,
            contactEmail: "",
            timezone: "",
            title: "",
            status: DefaultPanelOverrideStatus.idle
        )
    }
}
