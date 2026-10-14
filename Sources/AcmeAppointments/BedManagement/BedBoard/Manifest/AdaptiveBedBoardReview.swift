import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive bed board review is in its life cycle.
    enum AdaptiveBedBoardReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive bed board review. Its code is unique within a tenant.
    final class AdaptiveBedBoardReview {
        var code: String
        var name: String
        var limit: Int
        var unit: String
        var ratio: Double
        var allergy: String
        var status: AdaptiveBedBoardReviewStatus

        init(code: String, name: String, limit: Int, unit: String, ratio: Double, allergy: String, status: AdaptiveBedBoardReviewStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.unit = unit
            self.ratio = ratio
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveBedBoardReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveBedBoardReviewStatus.archived
            case .resolved:
                return next == AdaptiveBedBoardReviewStatus.reopened || next == AdaptiveBedBoardReviewStatus.archived
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

        func moveTo(_ next: AdaptiveBedBoardReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive bed board review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedLoad() -> Double {
            return (ratio * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveBedBoardReview {
            return AdaptiveBedBoardReview(
                code: code,
                name: name,
                limit: limit,
                unit: unit,
                ratio: ratio,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive bed board review in status open.
    static func newAdaptiveBedBoardReview(_ code: String, name: String) -> AdaptiveBedBoardReview {
        return AdaptiveBedBoardReview(
            code: code,
            name: name,
            limit: 0,
            unit: "",
            ratio: 0.0,
            allergy: "",
            status: AdaptiveBedBoardReviewStatus.`open`
        )
    }
}
