import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending witness draft is in its life cycle.
    enum PendingWitnessDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One pending witness draft, with what the planners need to act on it.
    final class PendingWitnessDraft {
        var code: String
        var name: String
        var graceDays: Int
        var bed: String
        var channel: String
        var diagnosisCode: String
        var retries: Int
        var clinicianID: String
        var sequence: Int
        var status: PendingWitnessDraftStatus

        init(code: String, name: String, graceDays: Int, bed: String, channel: String, diagnosisCode: String, retries: Int, clinicianID: String, sequence: Int, status: PendingWitnessDraftStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.bed = bed
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.retries = retries
            self.clinicianID = clinicianID
            self.sequence = sequence
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

        func canMoveTo(_ next: PendingWitnessDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingWitnessDraftStatus.inReview || next == PendingWitnessDraftStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingWitnessDraftStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PendingWitnessDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending witness draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending witness draft") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(retries) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PendingWitnessDraft {
            return PendingWitnessDraft(
                code: code,
                name: name,
                graceDays: graceDays,
                bed: bed,
                channel: channel,
                diagnosisCode: diagnosisCode,
                retries: retries,
                clinicianID: clinicianID,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending witness draft in status open.
    static func newPendingWitnessDraft(_ code: String, name: String) -> PendingWitnessDraft {
        return PendingWitnessDraft(
            code: code,
            name: name,
            graceDays: 0,
            bed: "",
            channel: "",
            diagnosisCode: "",
            retries: 0,
            clinicianID: "",
            sequence: 0,
            status: PendingWitnessDraftStatus.`open`
        )
    }
}
