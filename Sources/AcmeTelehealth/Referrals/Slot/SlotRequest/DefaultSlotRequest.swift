import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default slot request is in its life cycle.
    enum DefaultSlotRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default slot request as the slot team keeps it.
    final class DefaultSlotRequest {
        var code: String
        var label: String
        var dosageMg: Double
        var ratio: Double
        var procedureCode: String
        var status: DefaultSlotRequestStatus

        init(code: String, label: String, dosageMg: Double, ratio: Double, procedureCode: String, status: DefaultSlotRequestStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.ratio = ratio
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: DefaultSlotRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultSlotRequestStatus.rejected || next == DefaultSlotRequestStatus.withdrawn
            case .rejected:
                return next == DefaultSlotRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSlotRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default slot request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return ((ratio + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSlotRequest {
            return DefaultSlotRequest(
                code: code,
                label: label,
                dosageMg: dosageMg,
                ratio: ratio,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default slot request in status proposed.
    static func newDefaultSlotRequest(_ code: String, label: String) -> DefaultSlotRequest {
        return DefaultSlotRequest(
            code: code,
            label: label,
            dosageMg: 0.0,
            ratio: 0.0,
            procedureCode: "",
            status: DefaultSlotRequestStatus.proposed
        )
    }
}
