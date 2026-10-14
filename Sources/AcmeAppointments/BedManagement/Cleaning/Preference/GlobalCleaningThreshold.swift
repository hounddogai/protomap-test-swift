import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global cleaning threshold is in its life cycle.
    enum GlobalCleaningThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a global cleaning threshold and its current status.
    final class GlobalCleaningThreshold {
        var code: String
        var label: String
        var retries: Int
        var cost: Double
        var summary: String
        var active: Bool
        var bed: String
        var discount: Double
        var status: GlobalCleaningThresholdStatus

        init(code: String, label: String, retries: Int, cost: Double, summary: String, active: Bool, bed: String, discount: Double, status: GlobalCleaningThresholdStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.cost = cost
            self.summary = summary
            self.active = active
            self.bed = bed
            self.discount = discount
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

        func canMoveTo(_ next: GlobalCleaningThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalCleaningThresholdStatus.rejected || next == GlobalCleaningThresholdStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalCleaningThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global cleaning threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveVolume() -> Double {
            return ((discount - cost) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCleaningThreshold {
            return GlobalCleaningThreshold(
                code: code,
                label: label,
                retries: retries,
                cost: cost,
                summary: summary,
                active: active,
                bed: bed,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global cleaning threshold in status proposed.
    static func newGlobalCleaningThreshold(_ code: String, label: String) -> GlobalCleaningThreshold {
        return GlobalCleaningThreshold(
            code: code,
            label: label,
            retries: 0,
            cost: 0.0,
            summary: "",
            active: false,
            bed: "",
            discount: 0.0,
            status: GlobalCleaningThresholdStatus.proposed
        )
    }
}
