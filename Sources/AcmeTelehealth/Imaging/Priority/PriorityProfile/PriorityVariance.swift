import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority variance is in its life cycle.
    enum PriorityVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a priority variance and its current status.
    final class PriorityVariance {
        var code: String
        var label: String
        var category: String
        var source: String
        var allergy: String
        var payer: String
        var cost: Double
        var pinned: Bool
        var archived: Bool
        var status: PriorityVarianceStatus

        init(code: String, label: String, category: String, source: String, allergy: String, payer: String, cost: Double, pinned: Bool, archived: Bool, status: PriorityVarianceStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.source = source
            self.allergy = allergy
            self.payer = payer
            self.cost = cost
            self.pinned = pinned
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PriorityVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("priority variance") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> PriorityVariance {
            return PriorityVariance(
                code: code,
                label: label,
                category: category,
                source: source,
                allergy: allergy,
                payer: payer,
                cost: cost,
                pinned: pinned,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a priority variance in status requested.
    static func newPriorityVariance(_ code: String, label: String) -> PriorityVariance {
        return PriorityVariance(
            code: code,
            label: label,
            category: "",
            source: "",
            allergy: "",
            payer: "",
            cost: 0.0,
            pinned: false,
            archived: false,
            status: PriorityVarianceStatus.requested
        )
    }
}
