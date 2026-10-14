import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped courier review is in its life cycle.
    enum CappedCourierReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped courier review. Its code is unique within a tenant.
    final class CappedCourierReview {
        var code: String
        var title: String
        var procedureCode: String
        var ratio: Double
        var durationMinutes: Int
        var expiresAt: Int
        var visitMinutes: Int
        var priority: Int
        var status: CappedCourierReviewStatus

        init(code: String, title: String, procedureCode: String, ratio: Double, durationMinutes: Int, expiresAt: Int, visitMinutes: Int, priority: Int, status: CappedCourierReviewStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.visitMinutes = visitMinutes
            self.priority = priority
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

        func canMoveTo(_ next: CappedCourierReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedCourierReviewStatus.draining
            case .warming:
                return next == CappedCourierReviewStatus.ready || next == CappedCourierReviewStatus.stopped
            case .ready:
                return next == CappedCourierReviewStatus.stopped
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

        func moveTo(_ next: CappedCourierReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped courier review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(durationMinutes) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCourierReview {
            return CappedCourierReview(
                code: code,
                title: title,
                procedureCode: procedureCode,
                ratio: ratio,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                visitMinutes: visitMinutes,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped courier review in status idle.
    static func newCappedCourierReview(_ code: String, title: String) -> CappedCourierReview {
        return CappedCourierReview(
            code: code,
            title: title,
            procedureCode: "",
            ratio: 0.0,
            durationMinutes: 0,
            expiresAt: 0,
            visitMinutes: 0,
            priority: 0,
            status: CappedCourierReviewStatus.idle
        )
    }
}
