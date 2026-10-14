import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled consent form allocation is in its life cycle.
    enum ScheduledConsentFormAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled consent form allocation. Its code is unique within a tenant.
    final class ScheduledConsentFormAllocation {
        var code: String
        var label: String
        var attributes: [String: String]
        var source: String
        var ownerID: String
        var currency: String
        var timezone: String
        var durationMinutes: Int
        var status: ScheduledConsentFormAllocationStatus

        init(code: String, label: String, attributes: [String: String], source: String, ownerID: String, currency: String, timezone: String, durationMinutes: Int, status: ScheduledConsentFormAllocationStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.source = source
            self.ownerID = ownerID
            self.currency = currency
            self.timezone = timezone
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledConsentFormAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledConsentFormAllocationStatus.scheduled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ScheduledConsentFormAllocationStatus.completed || next == ScheduledConsentFormAllocationStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ScheduledConsentFormAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled consent form allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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
            return Double(durationMinutes)
        }

        func copyValue() -> ScheduledConsentFormAllocation {
            return ScheduledConsentFormAllocation(
                code: code,
                label: label,
                attributes: attributes,
                source: source,
                ownerID: ownerID,
                currency: currency,
                timezone: timezone,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled consent form allocation in status planned.
    static func newScheduledConsentFormAllocation(_ code: String, label: String) -> ScheduledConsentFormAllocation {
        return ScheduledConsentFormAllocation(
            code: code,
            label: label,
            attributes: [:],
            source: "",
            ownerID: "",
            currency: "",
            timezone: "",
            durationMinutes: 0,
            status: ScheduledConsentFormAllocationStatus.planned
        )
    }
}
