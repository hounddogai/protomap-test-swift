import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy budget is in its life cycle.
    enum ProxyBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a proxy budget and its current status.
    final class ProxyBudget {
        var code: String
        var name: String
        var durationMinutes: Int
        var maximum: Double
        var allergy: String
        var margin: Double
        var floorValue: Double
        var approved: Bool
        var tags: [String]
        var status: ProxyBudgetStatus

        init(code: String, name: String, durationMinutes: Int, maximum: Double, allergy: String, margin: Double, floorValue: Double, approved: Bool, tags: [String], status: ProxyBudgetStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.allergy = allergy
            self.margin = margin
            self.floorValue = floorValue
            self.approved = approved
            self.tags = tags
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

        func canMoveTo(_ next: ProxyBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == ProxyBudgetStatus.warming || next == ProxyBudgetStatus.ready
            case .warming:
                return next == ProxyBudgetStatus.stopped
            case .ready:
                return next == ProxyBudgetStatus.draining
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

        func moveTo(_ next: ProxyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (maximum * margin * 100).rounded() / 100
        }

        func copyValue() -> ProxyBudget {
            return ProxyBudget(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                maximum: maximum,
                allergy: allergy,
                margin: margin,
                floorValue: floorValue,
                approved: approved,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy budget in status idle.
    static func newProxyBudget(_ code: String, name: String) -> ProxyBudget {
        return ProxyBudget(
            code: code,
            name: name,
            durationMinutes: 0,
            maximum: 0.0,
            allergy: "",
            margin: 0.0,
            floorValue: 0.0,
            approved: false,
            tags: [],
            status: ProxyBudgetStatus.idle
        )
    }
}
