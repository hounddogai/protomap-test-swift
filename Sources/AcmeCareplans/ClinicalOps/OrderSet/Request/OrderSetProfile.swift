import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set profile is in its life cycle.
    enum OrderSetProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a order set profile and its current status.
    final class OrderSetProfile {
        var code: String
        var name: String
        var phone: String
        var description: String
        var label: String
        var rate: Double
        var status: OrderSetProfileStatus

        init(code: String, name: String, phone: String, description: String, label: String, rate: Double, status: OrderSetProfileStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.description = description
            self.label = label
            self.rate = rate
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

        func canMoveTo(_ next: OrderSetProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OrderSetProfileStatus.closed
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

        func moveTo(_ next: OrderSetProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("order set profile") \(code)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> OrderSetProfile {
            return OrderSetProfile(
                code: code,
                name: name,
                phone: phone,
                description: description,
                label: label,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set profile in status draft.
    static func newOrderSetProfile(_ code: String, name: String) -> OrderSetProfile {
        return OrderSetProfile(
            code: code,
            name: name,
            phone: "",
            description: "",
            label: "",
            rate: 0.0,
            status: OrderSetProfileStatus.draft
        )
    }
}
