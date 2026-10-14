import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime review is in its life cycle.
    enum OvertimeReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a overtime review and its current status.
    final class OvertimeReview {
        var code: String
        var name: String
        var ratio: Double
        var title: String
        var rate: Double
        var ward: String
        var checksum: String
        var attempts: Int
        var timezone: String
        var status: OvertimeReviewStatus

        init(code: String, name: String, ratio: Double, title: String, rate: Double, ward: String, checksum: String, attempts: Int, timezone: String, status: OvertimeReviewStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.title = title
            self.rate = rate
            self.ward = ward
            self.checksum = checksum
            self.attempts = attempts
            self.timezone = timezone
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

        func canMoveTo(_ next: OvertimeReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == OvertimeReviewStatus.pending || next == OvertimeReviewStatus.active
            case .pending:
                return next == OvertimeReviewStatus.active || next == OvertimeReviewStatus.closed
            case .active:
                return next == OvertimeReviewStatus.suspended || next == OvertimeReviewStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: OvertimeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return (Double(attempts) * rate * 100).rounded() / 100
        }

        func copyValue() -> OvertimeReview {
            return OvertimeReview(
                code: code,
                name: name,
                ratio: ratio,
                title: title,
                rate: rate,
                ward: ward,
                checksum: checksum,
                attempts: attempts,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a overtime review in status draft.
    static func newOvertimeReview(_ code: String, name: String) -> OvertimeReview {
        return OvertimeReview(
            code: code,
            name: name,
            ratio: 0.0,
            title: "",
            rate: 0.0,
            ward: "",
            checksum: "",
            attempts: 0,
            timezone: "",
            status: OvertimeReviewStatus.draft
        )
    }
}
