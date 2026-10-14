import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted handoff manifest is in its life cycle.
    enum WeightedHandoffManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted handoff manifest. Its code is unique within a tenant.
    final class WeightedHandoffManifest {
        var code: String
        var title: String
        var bed: String
        var cost: Double
        var amount: Double
        var status: WeightedHandoffManifestStatus

        init(code: String, title: String, bed: String, cost: Double, amount: Double, status: WeightedHandoffManifestStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.cost = cost
            self.amount = amount
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

        func canMoveTo(_ next: WeightedHandoffManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedHandoffManifestStatus.archived
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

        func moveTo(_ next: WeightedHandoffManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted handoff manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted handoff manifest") \(code)"
        }

        func netExposure() -> Double {
            return ((amount - cost) * 100).rounded() / 100
        }

        func copyValue() -> WeightedHandoffManifest {
            return WeightedHandoffManifest(
                code: code,
                title: title,
                bed: bed,
                cost: cost,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted handoff manifest in status open.
    static func newWeightedHandoffManifest(_ code: String, title: String) -> WeightedHandoffManifest {
        return WeightedHandoffManifest(
            code: code,
            title: title,
            bed: "",
            cost: 0.0,
            amount: 0.0,
            status: WeightedHandoffManifestStatus.`open`
        )
    }
}
