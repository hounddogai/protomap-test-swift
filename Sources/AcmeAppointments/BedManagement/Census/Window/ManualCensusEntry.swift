import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual census entry is in its life cycle.
    enum ManualCensusEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual census entry and its current status.
    final class ManualCensusEntry {
        var code: String
        var title: String
        var externalRef: String
        var region: String
        var country: String
        var contactEmail: String
        var attempts: Int
        var checksum: String
        var status: ManualCensusEntryStatus

        init(code: String, title: String, externalRef: String, region: String, country: String, contactEmail: String, attempts: Int, checksum: String, status: ManualCensusEntryStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.region = region
            self.country = country
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.checksum = checksum
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

        func canMoveTo(_ next: ManualCensusEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ManualCensusEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCensusEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual census entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> ManualCensusEntry {
            return ManualCensusEntry(
                code: code,
                title: title,
                externalRef: externalRef,
                region: region,
                country: country,
                contactEmail: contactEmail,
                attempts: attempts,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual census entry in status idle.
    static func newManualCensusEntry(_ code: String, title: String) -> ManualCensusEntry {
        return ManualCensusEntry(
            code: code,
            title: title,
            externalRef: "",
            region: "",
            country: "",
            contactEmail: "",
            attempts: 0,
            checksum: "",
            status: ManualCensusEntryStatus.idle
        )
    }
}
