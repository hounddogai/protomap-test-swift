import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive consent form checkpoint is in its life cycle.
    enum AdaptiveConsentFormCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One adaptive consent form checkpoint, with what the planners need to act on it.
    final class AdaptiveConsentFormCheckpoint {
        var code: String
        var title: String
        var version: Int
        var sequence: Int
        var clinicianID: String
        var name: String
        var archived: Bool
        var rate: Double
        var summary: String
        var currency: String
        var status: AdaptiveConsentFormCheckpointStatus

        init(code: String, title: String, version: Int, sequence: Int, clinicianID: String, name: String, archived: Bool, rate: Double, summary: String, currency: String, status: AdaptiveConsentFormCheckpointStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.sequence = sequence
            self.clinicianID = clinicianID
            self.name = name
            self.archived = archived
            self.rate = rate
            self.summary = summary
            self.currency = currency
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

        func canMoveTo(_ next: AdaptiveConsentFormCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AdaptiveConsentFormCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveConsentFormCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive consent form checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("adaptive consent form checkpoint") \(code)"
        }

        func netExposure() -> Double {
            return (rate * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveConsentFormCheckpoint {
            return AdaptiveConsentFormCheckpoint(
                code: code,
                title: title,
                version: version,
                sequence: sequence,
                clinicianID: clinicianID,
                name: name,
                archived: archived,
                rate: rate,
                summary: summary,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive consent form checkpoint in status planned.
    static func newAdaptiveConsentFormCheckpoint(_ code: String, title: String) -> AdaptiveConsentFormCheckpoint {
        return AdaptiveConsentFormCheckpoint(
            code: code,
            title: title,
            version: 0,
            sequence: 0,
            clinicianID: "",
            name: "",
            archived: false,
            rate: 0.0,
            summary: "",
            currency: "",
            status: AdaptiveConsentFormCheckpointStatus.planned
        )
    }
}
