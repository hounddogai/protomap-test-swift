import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality bundle is in its life cycle.
    enum ModalityBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A modality bundle as the modality team keeps it.
    final class ModalityBundle {
        var code: String
        var label: String
        var minimum: Double
        var unit: String
        var bed: String
        var status: ModalityBundleStatus

        init(code: String, label: String, minimum: Double, unit: String, bed: String, status: ModalityBundleStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.unit = unit
            self.bed = bed
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

        func canMoveTo(_ next: ModalityBundleStatus) -> Bool {
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
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ModalityBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("modality bundle") \(code)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> ModalityBundle {
            return ModalityBundle(code: code, label: label, minimum: minimum, unit: unit, bed: bed, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a modality bundle in status proposed.
    static func newModalityBundle(_ code: String, label: String) -> ModalityBundle {
        return ModalityBundle(
            code: code,
            label: label,
            minimum: 0.0,
            unit: "",
            bed: "",
            status: ModalityBundleStatus.proposed
        )
    }
}
