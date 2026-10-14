import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set variance is in its life cycle.
    enum OrderSetVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One order set variance, with what the planners need to act on it.
    final class OrderSetVariance {
        var code: String
        var label: String
        var score: Double
        var approved: Bool
        var discount: Double
        var acuity: Int
        var category: String
        var endsAt: Int
        var status: OrderSetVarianceStatus

        init(code: String, label: String, score: Double, approved: Bool, discount: Double, acuity: Int, category: String, endsAt: Int, status: OrderSetVarianceStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.approved = approved
            self.discount = discount
            self.acuity = acuity
            self.category = category
            self.endsAt = endsAt
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

        func canMoveTo(_ next: OrderSetVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == OrderSetVarianceStatus.resolved || next == OrderSetVarianceStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OrderSetVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("order set variance") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetVariance {
            return OrderSetVariance(
                code: code,
                label: label,
                score: score,
                approved: approved,
                discount: discount,
                acuity: acuity,
                category: category,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a order set variance in status open.
    static func newOrderSetVariance(_ code: String, label: String) -> OrderSetVariance {
        return OrderSetVariance(
            code: code,
            label: label,
            score: 0.0,
            approved: false,
            discount: 0.0,
            acuity: 0,
            category: "",
            endsAt: 0,
            status: OrderSetVarianceStatus.`open`
        )
    }
}
