import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted interaction exception is in its life cycle.
    enum WeightedInteractionExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted interaction exception, with what the planners need to act on it.
    final class WeightedInteractionException {
        var code: String
        var title: String
        var country: String
        var weight: Double
        var reviewer: String
        var procedureCode: String
        var rate: Double
        var status: WeightedInteractionExceptionStatus

        init(code: String, title: String, country: String, weight: Double, reviewer: String, procedureCode: String, rate: Double, status: WeightedInteractionExceptionStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.weight = weight
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.rate = rate
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

        func canMoveTo(_ next: WeightedInteractionExceptionStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedInteractionExceptionStatus.validated || next == WeightedInteractionExceptionStatus.published
            case .validated:
                return next == WeightedInteractionExceptionStatus.published || next == WeightedInteractionExceptionStatus.retired
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

        func moveTo(_ next: WeightedInteractionExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted interaction exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return (rate * weight * 100).rounded() / 100
        }

        func copyValue() -> WeightedInteractionException {
            return WeightedInteractionException(
                code: code,
                title: title,
                country: country,
                weight: weight,
                reviewer: reviewer,
                procedureCode: procedureCode,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted interaction exception in status created.
    static func newWeightedInteractionException(_ code: String, title: String) -> WeightedInteractionException {
        return WeightedInteractionException(
            code: code,
            title: title,
            country: "",
            weight: 0.0,
            reviewer: "",
            procedureCode: "",
            rate: 0.0,
            status: WeightedInteractionExceptionStatus.created
        )
    }
}
