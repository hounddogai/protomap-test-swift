import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness variance is in its life cycle.
    enum WitnessVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A witness variance as the witness team keeps it.
    final class WitnessVariance {
        var code: String
        var label: String
        var encounterID: String
        var timezone: String
        var contactEmail: String
        var ratio: Double
        var retries: Int
        var summary: String
        var endsAt: Int
        var capacity: Int
        var graceDays: Int
        var status: WitnessVarianceStatus

        init(code: String, label: String, encounterID: String, timezone: String, contactEmail: String, ratio: Double, retries: Int, summary: String, endsAt: Int, capacity: Int, graceDays: Int, status: WitnessVarianceStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.timezone = timezone
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.retries = retries
            self.summary = summary
            self.endsAt = endsAt
            self.capacity = capacity
            self.graceDays = graceDays
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

        func canMoveTo(_ next: WitnessVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == WitnessVarianceStatus.suspended || next == WitnessVarianceStatus.closed
            case .pending:
                return next == WitnessVarianceStatus.active || next == WitnessVarianceStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WitnessVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("witness variance") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(capacity) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessVariance {
            return WitnessVariance(
                code: code,
                label: label,
                encounterID: encounterID,
                timezone: timezone,
                contactEmail: contactEmail,
                ratio: ratio,
                retries: retries,
                summary: summary,
                endsAt: endsAt,
                capacity: capacity,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness variance in status draft.
    static func newWitnessVariance(_ code: String, label: String) -> WitnessVariance {
        return WitnessVariance(
            code: code,
            label: label,
            encounterID: "",
            timezone: "",
            contactEmail: "",
            ratio: 0.0,
            retries: 0,
            summary: "",
            endsAt: 0,
            capacity: 0,
            graceDays: 0,
            status: WitnessVarianceStatus.draft
        )
    }
}
