import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure override is in its life cycle.
    enum DisclosureOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One disclosure override, with what the planners need to act on it.
    final class DisclosureOverride {
        var code: String
        var label: String
        var currency: String
        var batchSize: Int
        var capacity: Int
        var checksum: String
        var name: String
        var encounterID: String
        var externalRef: String
        var expiresAt: Int
        var retries: Int
        var status: DisclosureOverrideStatus

        init(code: String, label: String, currency: String, batchSize: Int, capacity: Int, checksum: String, name: String, encounterID: String, externalRef: String, expiresAt: Int, retries: Int, status: DisclosureOverrideStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.batchSize = batchSize
            self.capacity = capacity
            self.checksum = checksum
            self.name = name
            self.encounterID = encounterID
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.retries = retries
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

        func canMoveTo(_ next: DisclosureOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DisclosureOverrideStatus.reopened || next == DisclosureOverrideStatus.archived
            case .reopened:
                return next == DisclosureOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("disclosure override") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(retries) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureOverride {
            return DisclosureOverride(
                code: code,
                label: label,
                currency: currency,
                batchSize: batchSize,
                capacity: capacity,
                checksum: checksum,
                name: name,
                encounterID: encounterID,
                externalRef: externalRef,
                expiresAt: expiresAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure override in status open.
    static func newDisclosureOverride(_ code: String, label: String) -> DisclosureOverride {
        return DisclosureOverride(
            code: code,
            label: label,
            currency: "",
            batchSize: 0,
            capacity: 0,
            checksum: "",
            name: "",
            encounterID: "",
            externalRef: "",
            expiresAt: 0,
            retries: 0,
            status: DisclosureOverrideStatus.`open`
        )
    }
}
