import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted program claim is in its life cycle.
    enum WeightedProgramClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted program claim, with what the planners need to act on it.
    final class WeightedProgramClaim {
        var code: String
        var label: String
        var externalRef: String
        var reviewer: String
        var procedureCode: String
        var source: String
        var cost: Double
        var priority: Int
        var discount: Double
        var archived: Bool
        var status: WeightedProgramClaimStatus

        init(code: String, label: String, externalRef: String, reviewer: String, procedureCode: String, source: String, cost: Double, priority: Int, discount: Double, archived: Bool, status: WeightedProgramClaimStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.source = source
            self.cost = cost
            self.priority = priority
            self.discount = discount
            self.archived = archived
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

        func canMoveTo(_ next: WeightedProgramClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WeightedProgramClaimStatus.retired
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

        func moveTo(_ next: WeightedProgramClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted program claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return (cost * discount * 100).rounded() / 100
        }

        func copyValue() -> WeightedProgramClaim {
            return WeightedProgramClaim(
                code: code,
                label: label,
                externalRef: externalRef,
                reviewer: reviewer,
                procedureCode: procedureCode,
                source: source,
                cost: cost,
                priority: priority,
                discount: discount,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted program claim in status created.
    static func newWeightedProgramClaim(_ code: String, label: String) -> WeightedProgramClaim {
        return WeightedProgramClaim(
            code: code,
            label: label,
            externalRef: "",
            reviewer: "",
            procedureCode: "",
            source: "",
            cost: 0.0,
            priority: 0,
            discount: 0.0,
            archived: false,
            status: WeightedProgramClaimStatus.created
        )
    }
}
