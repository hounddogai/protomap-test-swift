import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial summary is in its life cycle.
    enum DenialSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a denial summary and its current status.
    final class DenialSummary {
        var code: String
        var title: String
        var diagnosisCode: String
        var encounterID: String
        var archived: Bool
        var amount: Double
        var notes: String
        var weight: Double
        var status: DenialSummaryStatus

        init(code: String, title: String, diagnosisCode: String, encounterID: String, archived: Bool, amount: Double, notes: String, weight: Double, status: DenialSummaryStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.archived = archived
            self.amount = amount
            self.notes = notes
            self.weight = weight
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

        func canMoveTo(_ next: DenialSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == DenialSummaryStatus.stopped
            case .warming:
                return next == DenialSummaryStatus.draining || next == DenialSummaryStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return ((weight - amount) * 100).rounded() / 100
        }

        func copyValue() -> DenialSummary {
            return DenialSummary(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                encounterID: encounterID,
                archived: archived,
                amount: amount,
                notes: notes,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial summary in status idle.
    static func newDenialSummary(_ code: String, title: String) -> DenialSummary {
        return DenialSummary(
            code: code,
            title: title,
            diagnosisCode: "",
            encounterID: "",
            archived: false,
            amount: 0.0,
            notes: "",
            weight: 0.0,
            status: DenialSummaryStatus.idle
        )
    }
}
