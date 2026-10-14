import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense threshold is in its life cycle.
    enum DispenseThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a dispense threshold and its current status.
    final class DispenseThreshold {
        var code: String
        var label: String
        var visible: Bool
        var source: String
        var graceDays: Int
        var notes: String
        var retries: Int
        var status: DispenseThresholdStatus

        init(code: String, label: String, visible: Bool, source: String, graceDays: Int, notes: String, retries: Int, status: DispenseThresholdStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.source = source
            self.graceDays = graceDays
            self.notes = notes
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DispenseThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return (Double(retries) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> DispenseThreshold {
            return DispenseThreshold(
                code: code,
                label: label,
                visible: visible,
                source: source,
                graceDays: graceDays,
                notes: notes,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a dispense threshold in status planned.
    static func newDispenseThreshold(_ code: String, label: String) -> DispenseThreshold {
        return DispenseThreshold(
            code: code,
            label: label,
            visible: false,
            source: "",
            graceDays: 0,
            notes: "",
            retries: 0,
            status: DispenseThresholdStatus.planned
        )
    }
}
