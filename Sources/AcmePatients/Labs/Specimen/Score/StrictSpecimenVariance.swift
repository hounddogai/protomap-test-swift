import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict specimen variance is in its life cycle.
    enum StrictSpecimenVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict specimen variance and its current status.
    final class StrictSpecimenVariance {
        var code: String
        var title: String
        var source: String
        var name: String
        var phone: String
        var score: Double
        var status: StrictSpecimenVarianceStatus

        init(code: String, title: String, source: String, name: String, phone: String, score: Double, status: StrictSpecimenVarianceStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.name = name
            self.phone = phone
            self.score = score
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

        func canMoveTo(_ next: StrictSpecimenVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictSpecimenVarianceStatus.approved || next == StrictSpecimenVarianceStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StrictSpecimenVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSpecimenVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict specimen variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict specimen variance") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> StrictSpecimenVariance {
            return StrictSpecimenVariance(
                code: code,
                title: title,
                source: source,
                name: name,
                phone: phone,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict specimen variance in status proposed.
    static func newStrictSpecimenVariance(_ code: String, title: String) -> StrictSpecimenVariance {
        return StrictSpecimenVariance(
            code: code,
            title: title,
            source: "",
            name: "",
            phone: "",
            score: 0.0,
            status: StrictSpecimenVarianceStatus.proposed
        )
    }
}
