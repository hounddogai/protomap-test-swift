import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment review is in its life cycle.
    enum AssessmentReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A assessment review as the assessment team keeps it.
    final class AssessmentReview {
        var code: String
        var title: String
        var description: String
        var ward: String
        var visible: Bool
        var segment: String
        var discount: Double
        var createdAt: Int
        var status: AssessmentReviewStatus

        init(code: String, title: String, description: String, ward: String, visible: Bool, segment: String, discount: Double, createdAt: Int, status: AssessmentReviewStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.ward = ward
            self.visible = visible
            self.segment = segment
            self.discount = discount
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == AssessmentReviewStatus.draining || next == AssessmentReviewStatus.stopped
            case .warming:
                return next == AssessmentReviewStatus.stopped
            case .ready:
                return next == AssessmentReviewStatus.draining || next == AssessmentReviewStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AssessmentReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (Double(createdAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> AssessmentReview {
            return AssessmentReview(
                code: code,
                title: title,
                description: description,
                ward: ward,
                visible: visible,
                segment: segment,
                discount: discount,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a assessment review in status idle.
    static func newAssessmentReview(_ code: String, title: String) -> AssessmentReview {
        return AssessmentReview(
            code: code,
            title: title,
            description: "",
            ward: "",
            visible: false,
            segment: "",
            discount: 0.0,
            createdAt: 0,
            status: AssessmentReviewStatus.idle
        )
    }
}
