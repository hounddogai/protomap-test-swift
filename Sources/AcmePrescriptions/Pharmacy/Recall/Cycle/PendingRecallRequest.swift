import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall request is in its life cycle.
    enum PendingRecallRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending recall request as the recall team keeps it.
    final class PendingRecallRequest {
        var code: String
        var title: String
        var currency: String
        var checksum: String
        var attempts: Int
        var startsAt: Int
        var refills: Int
        var status: PendingRecallRequestStatus

        init(code: String, title: String, currency: String, checksum: String, attempts: Int, startsAt: Int, refills: Int, status: PendingRecallRequestStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.checksum = checksum
            self.attempts = attempts
            self.startsAt = startsAt
            self.refills = refills
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

        func canMoveTo(_ next: PendingRecallRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingRecallRequestStatus.inReview || next == PendingRecallRequestStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingRecallRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(refills) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallRequest {
            return PendingRecallRequest(
                code: code,
                title: title,
                currency: currency,
                checksum: checksum,
                attempts: attempts,
                startsAt: startsAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending recall request in status open.
    static func newPendingRecallRequest(_ code: String, title: String) -> PendingRecallRequest {
        return PendingRecallRequest(
            code: code,
            title: title,
            currency: "",
            checksum: "",
            attempts: 0,
            startsAt: 0,
            refills: 0,
            status: PendingRecallRequestStatus.`open`
        )
    }
}
