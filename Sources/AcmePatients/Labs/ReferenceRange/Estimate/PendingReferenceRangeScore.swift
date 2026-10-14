import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending reference range score is in its life cycle.
    enum PendingReferenceRangeScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One pending reference range score, with what the planners need to act on it.
    final class PendingReferenceRangeScore {
        var code: String
        var title: String
        var currency: String
        var externalRef: String
        var budget: Double
        var weight: Double
        var description: String
        var ceiling: Double
        var refills: Int
        var threshold: Double
        var revision: Int
        var status: PendingReferenceRangeScoreStatus

        init(code: String, title: String, currency: String, externalRef: String, budget: Double, weight: Double, description: String, ceiling: Double, refills: Int, threshold: Double, revision: Int, status: PendingReferenceRangeScoreStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.externalRef = externalRef
            self.budget = budget
            self.weight = weight
            self.description = description
            self.ceiling = ceiling
            self.refills = refills
            self.threshold = threshold
            self.revision = revision
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

        func canMoveTo(_ next: PendingReferenceRangeScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingReferenceRangeScoreStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PendingReferenceRangeScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReferenceRangeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending reference range score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return (threshold * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> PendingReferenceRangeScore {
            return PendingReferenceRangeScore(
                code: code,
                title: title,
                currency: currency,
                externalRef: externalRef,
                budget: budget,
                weight: weight,
                description: description,
                ceiling: ceiling,
                refills: refills,
                threshold: threshold,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending reference range score in status created.
    static func newPendingReferenceRangeScore(_ code: String, title: String) -> PendingReferenceRangeScore {
        return PendingReferenceRangeScore(
            code: code,
            title: title,
            currency: "",
            externalRef: "",
            budget: 0.0,
            weight: 0.0,
            description: "",
            ceiling: 0.0,
            refills: 0,
            threshold: 0.0,
            revision: 0,
            status: PendingReferenceRangeScoreStatus.created
        )
    }
}
