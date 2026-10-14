import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation review is in its life cycle.
    enum IsolationReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a isolation review and its current status.
    final class IsolationReview {
        var code: String
        var title: String
        var description: String
        var refills: Int
        var visible: Bool
        var phone: String
        var approved: Bool
        var floorValue: Double
        var payer: String
        var attempts: Int
        var status: IsolationReviewStatus

        init(code: String, title: String, description: String, refills: Int, visible: Bool, phone: String, approved: Bool, floorValue: Double, payer: String, attempts: Int, status: IsolationReviewStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.refills = refills
            self.visible = visible
            self.phone = phone
            self.approved = approved
            self.floorValue = floorValue
            self.payer = payer
            self.attempts = attempts
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

        func canMoveTo(_ next: IsolationReviewStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == IsolationReviewStatus.ready
            case .ready:
                return next == IsolationReviewStatus.draining || next == IsolationReviewStatus.stopped
            case .draining:
                return next == IsolationReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedVolume() -> Double {
            return ((Double(refills) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationReview {
            return IsolationReview(
                code: code,
                title: title,
                description: description,
                refills: refills,
                visible: visible,
                phone: phone,
                approved: approved,
                floorValue: floorValue,
                payer: payer,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation review in status idle.
    static func newIsolationReview(_ code: String, title: String) -> IsolationReview {
        return IsolationReview(
            code: code,
            title: title,
            description: "",
            refills: 0,
            visible: false,
            phone: "",
            approved: false,
            floorValue: 0.0,
            payer: "",
            attempts: 0,
            status: IsolationReviewStatus.idle
        )
    }
}
