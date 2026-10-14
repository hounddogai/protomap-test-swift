import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel group is in its life cycle.
    enum PanelGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A panel group as the panel team keeps it.
    final class PanelGroup {
        var code: String
        var name: String
        var category: String
        var amount: Double
        var limit: Int
        var refills: Int
        var budget: Double
        var status: PanelGroupStatus

        init(code: String, name: String, category: String, amount: Double, limit: Int, refills: Int, budget: Double, status: PanelGroupStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.amount = amount
            self.limit = limit
            self.refills = refills
            self.budget = budget
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

        func canMoveTo(_ next: PanelGroupStatus) -> Bool {
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
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PanelGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("panel group") \(code)"
        }

        func netVolume() -> Double {
            return (Double(limit) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> PanelGroup {
            return PanelGroup(
                code: code,
                name: name,
                category: category,
                amount: amount,
                limit: limit,
                refills: refills,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a panel group in status idle.
    static func newPanelGroup(_ code: String, name: String) -> PanelGroup {
        return PanelGroup(
            code: code,
            name: name,
            category: "",
            amount: 0.0,
            limit: 0,
            refills: 0,
            budget: 0.0,
            status: PanelGroupStatus.idle
        )
    }
}
