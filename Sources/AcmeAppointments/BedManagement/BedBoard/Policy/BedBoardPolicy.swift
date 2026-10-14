import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board policy is in its life cycle.
    enum BedBoardPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One bed board policy, with what the planners need to act on it.
    final class BedBoardPolicy {
        var code: String
        var title: String
        var segment: String
        var phone: String
        var name: String
        var acuity: Int
        var quantity: Int
        var status: BedBoardPolicyStatus

        init(code: String, title: String, segment: String, phone: String, name: String, acuity: Int, quantity: Int, status: BedBoardPolicyStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.phone = phone
            self.name = name
            self.acuity = acuity
            self.quantity = quantity
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

        func canMoveTo(_ next: BedBoardPolicyStatus) -> Bool {
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
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BedBoardPolicyStatus.reopened || next == BedBoardPolicyStatus.archived
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

        func moveTo(_ next: BedBoardPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("bed board policy") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(acuity) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardPolicy {
            return BedBoardPolicy(
                code: code,
                title: title,
                segment: segment,
                phone: phone,
                name: name,
                acuity: acuity,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a bed board policy in status open.
    static func newBedBoardPolicy(_ code: String, title: String) -> BedBoardPolicy {
        return BedBoardPolicy(
            code: code,
            title: title,
            segment: "",
            phone: "",
            name: "",
            acuity: 0,
            quantity: 0,
            status: BedBoardPolicyStatus.`open`
        )
    }
}
