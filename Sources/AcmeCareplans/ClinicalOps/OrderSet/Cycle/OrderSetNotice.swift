import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set notice is in its life cycle.
    enum OrderSetNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One order set notice, with what the planners need to act on it.
    final class OrderSetNotice {
        var code: String
        var name: String
        var description: String
        var tags: [String]
        var visitMinutes: Int
        var phone: String
        var cost: Double
        var attempts: Int
        var status: OrderSetNoticeStatus

        init(code: String, name: String, description: String, tags: [String], visitMinutes: Int, phone: String, cost: Double, attempts: Int, status: OrderSetNoticeStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.tags = tags
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.cost = cost
            self.attempts = attempts
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

        func canMoveTo(_ next: OrderSetNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == OrderSetNoticeStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OrderSetNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("order set notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((cost + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetNotice {
            return OrderSetNotice(
                code: code,
                name: name,
                description: description,
                tags: tags,
                visitMinutes: visitMinutes,
                phone: phone,
                cost: cost,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set notice in status proposed.
    static func newOrderSetNotice(_ code: String, name: String) -> OrderSetNotice {
        return OrderSetNotice(
            code: code,
            name: name,
            description: "",
            tags: [],
            visitMinutes: 0,
            phone: "",
            cost: 0.0,
            attempts: 0,
            status: OrderSetNoticeStatus.proposed
        )
    }
}
