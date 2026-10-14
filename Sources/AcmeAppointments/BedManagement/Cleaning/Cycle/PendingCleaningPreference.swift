import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending cleaning preference is in its life cycle.
    enum PendingCleaningPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One pending cleaning preference, with what the planners need to act on it.
    final class PendingCleaningPreference {
        var code: String
        var label: String
        var retries: Int
        var currency: String
        var externalRef: String
        var floorValue: Double
        var expiresAt: Int
        var channel: String
        var copay: Double
        var priority: Int
        var status: PendingCleaningPreferenceStatus

        init(code: String, label: String, retries: Int, currency: String, externalRef: String, floorValue: Double, expiresAt: Int, channel: String, copay: Double, priority: Int, status: PendingCleaningPreferenceStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.currency = currency
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.channel = channel
            self.copay = copay
            self.priority = priority
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

        func canMoveTo(_ next: PendingCleaningPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
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
                return next == PendingCleaningPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCleaningPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending cleaning preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (Double(retries) * copay * 100).rounded() / 100
        }

        func copyValue() -> PendingCleaningPreference {
            return PendingCleaningPreference(
                code: code,
                label: label,
                retries: retries,
                currency: currency,
                externalRef: externalRef,
                floorValue: floorValue,
                expiresAt: expiresAt,
                channel: channel,
                copay: copay,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending cleaning preference in status draft.
    static func newPendingCleaningPreference(_ code: String, label: String) -> PendingCleaningPreference {
        return PendingCleaningPreference(
            code: code,
            label: label,
            retries: 0,
            currency: "",
            externalRef: "",
            floorValue: 0.0,
            expiresAt: 0,
            channel: "",
            copay: 0.0,
            priority: 0,
            status: PendingCleaningPreferenceStatus.draft
        )
    }
}
