import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary interaction baseline is in its life cycle.
    enum PrimaryInteractionBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary interaction baseline, with what the planners need to act on it.
    final class PrimaryInteractionBaseline {
        var code: String
        var label: String
        var procedureCode: String
        var sequence: Int
        var amount: Double
        var dosageMg: Double
        var status: PrimaryInteractionBaselineStatus

        init(code: String, label: String, procedureCode: String, sequence: Int, amount: Double, dosageMg: Double, status: PrimaryInteractionBaselineStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.amount = amount
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: PrimaryInteractionBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryInteractionBaselineStatus.retired
            case .validated:
                return next == PrimaryInteractionBaselineStatus.published || next == PrimaryInteractionBaselineStatus.retired
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

        func moveTo(_ next: PrimaryInteractionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary interaction baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return ((amount - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInteractionBaseline {
            return PrimaryInteractionBaseline(
                code: code,
                label: label,
                procedureCode: procedureCode,
                sequence: sequence,
                amount: amount,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary interaction baseline in status created.
    static func newPrimaryInteractionBaseline(_ code: String, label: String) -> PrimaryInteractionBaseline {
        return PrimaryInteractionBaseline(
            code: code,
            label: label,
            procedureCode: "",
            sequence: 0,
            amount: 0.0,
            dosageMg: 0.0,
            status: PrimaryInteractionBaselineStatus.created
        )
    }
}
