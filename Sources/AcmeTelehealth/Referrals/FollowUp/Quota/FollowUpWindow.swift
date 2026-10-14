import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up window is in its life cycle.
    enum FollowUpWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One follow up window, with what the planners need to act on it.
    final class FollowUpWindow {
        var code: String
        var title: String
        var payer: String
        var dosageMg: Double
        var discount: Double
        var priority: Int
        var retries: Int
        var sequence: Int
        var attributes: [String: String]
        var status: FollowUpWindowStatus

        init(code: String, title: String, payer: String, dosageMg: Double, discount: Double, priority: Int, retries: Int, sequence: Int, attributes: [String: String], status: FollowUpWindowStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.dosageMg = dosageMg
            self.discount = discount
            self.priority = priority
            self.retries = retries
            self.sequence = sequence
            self.attributes = attributes
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

        func canMoveTo(_ next: FollowUpWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FollowUpWindowStatus.ready || next == FollowUpWindowStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FollowUpWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveValue() -> Double {
            return ((Double(retries) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpWindow {
            return FollowUpWindow(
                code: code,
                title: title,
                payer: payer,
                dosageMg: dosageMg,
                discount: discount,
                priority: priority,
                retries: retries,
                sequence: sequence,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up window in status idle.
    static func newFollowUpWindow(_ code: String, title: String) -> FollowUpWindow {
        return FollowUpWindow(
            code: code,
            title: title,
            payer: "",
            dosageMg: 0.0,
            discount: 0.0,
            priority: 0,
            retries: 0,
            sequence: 0,
            attributes: [:],
            status: FollowUpWindowStatus.idle
        )
    }
}
