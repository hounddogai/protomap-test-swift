import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped handoff target is in its life cycle.
    enum CappedHandoffTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped handoff target. Its code is unique within a tenant.
    final class CappedHandoffTarget {
        var code: String
        var name: String
        var windowDays: Int
        var active: Bool
        var budget: Double
        var channel: String
        var amount: Double
        var title: String
        var unit: String
        var procedureCode: String
        var status: CappedHandoffTargetStatus

        init(code: String, name: String, windowDays: Int, active: Bool, budget: Double, channel: String, amount: Double, title: String, unit: String, procedureCode: String, status: CappedHandoffTargetStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.active = active
            self.budget = budget
            self.channel = channel
            self.amount = amount
            self.title = title
            self.unit = unit
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: CappedHandoffTargetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedHandoffTargetStatus.retired
            case .published:
                return next == CappedHandoffTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedHandoffTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped handoff target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return (amount * budget * 100).rounded() / 100
        }

        func copyValue() -> CappedHandoffTarget {
            return CappedHandoffTarget(
                code: code,
                name: name,
                windowDays: windowDays,
                active: active,
                budget: budget,
                channel: channel,
                amount: amount,
                title: title,
                unit: unit,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped handoff target in status created.
    static func newCappedHandoffTarget(_ code: String, name: String) -> CappedHandoffTarget {
        return CappedHandoffTarget(
            code: code,
            name: name,
            windowDays: 0,
            active: false,
            budget: 0.0,
            channel: "",
            amount: 0.0,
            title: "",
            unit: "",
            procedureCode: "",
            status: CappedHandoffTargetStatus.created
        )
    }
}
