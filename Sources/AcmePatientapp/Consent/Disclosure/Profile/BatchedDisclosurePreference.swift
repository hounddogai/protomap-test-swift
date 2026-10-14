import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched disclosure preference is in its life cycle.
    enum BatchedDisclosurePreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched disclosure preference as the disclosure team keeps it.
    final class BatchedDisclosurePreference {
        var code: String
        var label: String
        var updatedAt: Int
        var encounterID: String
        var windowDays: Int
        var timezone: String
        var startsAt: Int
        var amount: Double
        var specialty: String
        var status: BatchedDisclosurePreferenceStatus

        init(code: String, label: String, updatedAt: Int, encounterID: String, windowDays: Int, timezone: String, startsAt: Int, amount: Double, specialty: String, status: BatchedDisclosurePreferenceStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.windowDays = windowDays
            self.timezone = timezone
            self.startsAt = startsAt
            self.amount = amount
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedDisclosurePreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedDisclosurePreferenceStatus.published
            case .validated:
                return next == BatchedDisclosurePreferenceStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BatchedDisclosurePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched disclosure preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched disclosure preference") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(startsAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDisclosurePreference {
            return BatchedDisclosurePreference(
                code: code,
                label: label,
                updatedAt: updatedAt,
                encounterID: encounterID,
                windowDays: windowDays,
                timezone: timezone,
                startsAt: startsAt,
                amount: amount,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched disclosure preference in status created.
    static func newBatchedDisclosurePreference(_ code: String, label: String) -> BatchedDisclosurePreference {
        return BatchedDisclosurePreference(
            code: code,
            label: label,
            updatedAt: 0,
            encounterID: "",
            windowDays: 0,
            timezone: "",
            startsAt: 0,
            amount: 0.0,
            specialty: "",
            status: BatchedDisclosurePreferenceStatus.created
        )
    }
}
