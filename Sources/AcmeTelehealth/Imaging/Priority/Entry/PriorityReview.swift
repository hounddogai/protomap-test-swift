import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority review is in its life cycle.
    enum PriorityReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A priority review. Its code is unique within a tenant.
    final class PriorityReview {
        var code: String
        var name: String
        var category: String
        var visible: Bool
        var ceiling: Double
        var batchSize: Int
        var status: PriorityReviewStatus

        init(code: String, name: String, category: String, visible: Bool, ceiling: Double, batchSize: Int, status: PriorityReviewStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.visible = visible
            self.ceiling = ceiling
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PriorityReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PriorityReviewStatus.approved
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PriorityReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return (Double(batchSize) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PriorityReview {
            return PriorityReview(
                code: code,
                name: name,
                category: category,
                visible: visible,
                ceiling: ceiling,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a priority review in status proposed.
    static func newPriorityReview(_ code: String, name: String) -> PriorityReview {
        return PriorityReview(
            code: code,
            name: name,
            category: "",
            visible: false,
            ceiling: 0.0,
            batchSize: 0,
            status: PriorityReviewStatus.proposed
        )
    }
}
