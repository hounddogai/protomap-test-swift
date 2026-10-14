import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction rule is in its life cycle.
    enum InteractionRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A interaction rule as the interaction team keeps it.
    final class InteractionRule {
        var code: String
        var name: String
        var sequence: Int
        var facility: String
        var windowDays: Int
        var unit: String
        var status: InteractionRuleStatus

        init(code: String, name: String, sequence: Int, facility: String, windowDays: Int, unit: String, status: InteractionRuleStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.facility = facility
            self.windowDays = windowDays
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == InteractionRuleStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: InteractionRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionRule {
            return InteractionRule(
                code: code,
                name: name,
                sequence: sequence,
                facility: facility,
                windowDays: windowDays,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a interaction rule in status created.
    static func newInteractionRule(_ code: String, name: String) -> InteractionRule {
        return InteractionRule(
            code: code,
            name: name,
            sequence: 0,
            facility: "",
            windowDays: 0,
            unit: "",
            status: InteractionRuleStatus.created
        )
    }
}
