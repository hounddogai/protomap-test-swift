import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive goal preference is in its life cycle.
    enum AdaptiveGoalPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive goal preference and its current status.
    final class AdaptiveGoalPreference {
        var code: String
        var label: String
        var maximum: Double
        var score: Double
        var limit: Int
        var retries: Int
        var source: String
        var contactEmail: String
        var checksum: String
        var amount: Double
        var visitMinutes: Int
        var status: AdaptiveGoalPreferenceStatus

        init(code: String, label: String, maximum: Double, score: Double, limit: Int, retries: Int, source: String, contactEmail: String, checksum: String, amount: Double, visitMinutes: Int, status: AdaptiveGoalPreferenceStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.score = score
            self.limit = limit
            self.retries = retries
            self.source = source
            self.contactEmail = contactEmail
            self.checksum = checksum
            self.amount = amount
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveGoalPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveGoalPreferenceStatus.withdrawn
            case .rejected:
                return next == AdaptiveGoalPreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveGoalPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive goal preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive goal preference") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(limit) - score) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveGoalPreference {
            return AdaptiveGoalPreference(
                code: code,
                label: label,
                maximum: maximum,
                score: score,
                limit: limit,
                retries: retries,
                source: source,
                contactEmail: contactEmail,
                checksum: checksum,
                amount: amount,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive goal preference in status proposed.
    static func newAdaptiveGoalPreference(_ code: String, label: String) -> AdaptiveGoalPreference {
        return AdaptiveGoalPreference(
            code: code,
            label: label,
            maximum: 0.0,
            score: 0.0,
            limit: 0,
            retries: 0,
            source: "",
            contactEmail: "",
            checksum: "",
            amount: 0.0,
            visitMinutes: 0,
            status: AdaptiveGoalPreferenceStatus.proposed
        )
    }
}
