import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted substitution profile is in its life cycle.
    enum WeightedSubstitutionProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted substitution profile as the substitution team keeps it.
    final class WeightedSubstitutionProfile {
        var code: String
        var name: String
        var title: String
        var score: Double
        var amount: Double
        var status: WeightedSubstitutionProfileStatus

        init(code: String, name: String, title: String, score: Double, amount: Double, status: WeightedSubstitutionProfileStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.score = score
            self.amount = amount
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

        func canMoveTo(_ next: WeightedSubstitutionProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WeightedSubstitutionProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSubstitutionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted substitution profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted substitution profile") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((score + amount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSubstitutionProfile {
            return WeightedSubstitutionProfile(
                code: code,
                name: name,
                title: title,
                score: score,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted substitution profile in status draft.
    static func newWeightedSubstitutionProfile(_ code: String, name: String) -> WeightedSubstitutionProfile {
        return WeightedSubstitutionProfile(
            code: code,
            name: name,
            title: "",
            score: 0.0,
            amount: 0.0,
            status: WeightedSubstitutionProfileStatus.draft
        )
    }
}
