import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense rule is in its life cycle.
    enum DispenseRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One dispense rule, with what the planners need to act on it.
    final class DispenseRule {
        var code: String
        var name: String
        var version: Int
        var externalRef: String
        var cost: Double
        var batchSize: Int
        var unit: String
        var status: DispenseRuleStatus

        init(code: String, name: String, version: Int, externalRef: String, cost: Double, batchSize: Int, unit: String, status: DispenseRuleStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.externalRef = externalRef
            self.cost = cost
            self.batchSize = batchSize
            self.unit = unit
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

        func canMoveTo(_ next: DispenseRuleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DispenseRuleStatus.ready || next == DispenseRuleStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DispenseRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((Double(batchSize) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseRule {
            return DispenseRule(
                code: code,
                name: name,
                version: version,
                externalRef: externalRef,
                cost: cost,
                batchSize: batchSize,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a dispense rule in status idle.
    static func newDispenseRule(_ code: String, name: String) -> DispenseRule {
        return DispenseRule(
            code: code,
            name: name,
            version: 0,
            externalRef: "",
            cost: 0.0,
            batchSize: 0,
            unit: "",
            status: DispenseRuleStatus.idle
        )
    }
}
