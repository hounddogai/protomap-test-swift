import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory request is in its life cycle.
    enum InventoryRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One inventory request, with what the planners need to act on it.
    final class InventoryRequest {
        var code: String
        var title: String
        var acuity: Int
        var locale: String
        var budget: Double
        var channel: String
        var refills: Int
        var status: InventoryRequestStatus

        init(code: String, title: String, acuity: Int, locale: String, budget: Double, channel: String, refills: Int, status: InventoryRequestStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.locale = locale
            self.budget = budget
            self.channel = channel
            self.refills = refills
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

        func canMoveTo(_ next: InventoryRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == InventoryRequestStatus.draining || next == InventoryRequestStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == InventoryRequestStatus.draining
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

        func moveTo(_ next: InventoryRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return (budget * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> InventoryRequest {
            return InventoryRequest(
                code: code,
                title: title,
                acuity: acuity,
                locale: locale,
                budget: budget,
                channel: channel,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a inventory request in status idle.
    static func newInventoryRequest(_ code: String, title: String) -> InventoryRequest {
        return InventoryRequest(
            code: code,
            title: title,
            acuity: 0,
            locale: "",
            budget: 0.0,
            channel: "",
            refills: 0,
            status: InventoryRequestStatus.idle
        )
    }
}
