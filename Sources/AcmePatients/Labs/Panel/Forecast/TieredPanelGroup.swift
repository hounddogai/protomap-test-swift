import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel group is in its life cycle.
    enum TieredPanelGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered panel group, with what the planners need to act on it.
    final class TieredPanelGroup {
        var code: String
        var title: String
        var acuity: Int
        var weight: Double
        var currency: String
        var limit: Int
        var status: TieredPanelGroupStatus

        init(code: String, title: String, acuity: Int, weight: Double, currency: String, limit: Int, status: TieredPanelGroupStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.weight = weight
            self.currency = currency
            self.limit = limit
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

        func canMoveTo(_ next: TieredPanelGroupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredPanelGroupStatus.withdrawn
            case .rejected:
                return next == TieredPanelGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPanelGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedTotal() -> Double {
            return ((Double(limit) + weight) * 100).rounded() / 100
        }

        func copyValue() -> TieredPanelGroup {
            return TieredPanelGroup(
                code: code,
                title: title,
                acuity: acuity,
                weight: weight,
                currency: currency,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered panel group in status proposed.
    static func newTieredPanelGroup(_ code: String, title: String) -> TieredPanelGroup {
        return TieredPanelGroup(
            code: code,
            title: title,
            acuity: 0,
            weight: 0.0,
            currency: "",
            limit: 0,
            status: TieredPanelGroupStatus.proposed
        )
    }
}
