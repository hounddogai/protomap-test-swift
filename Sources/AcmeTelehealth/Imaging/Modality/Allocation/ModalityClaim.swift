import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality claim is in its life cycle.
    enum ModalityClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality claim as the modality team keeps it.
    final class ModalityClaim {
        var code: String
        var label: String
        var externalRef: String
        var allergy: String
        var weight: Double
        var status: ModalityClaimStatus

        init(code: String, label: String, externalRef: String, allergy: String, weight: Double, status: ModalityClaimStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.allergy = allergy
            self.weight = weight
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

        func canMoveTo(_ next: ModalityClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == ModalityClaimStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ModalityClaimStatus.completed
            case .completed:
                return next == ModalityClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> ModalityClaim {
            return ModalityClaim(
                code: code,
                label: label,
                externalRef: externalRef,
                allergy: allergy,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality claim in status planned.
    static func newModalityClaim(_ code: String, label: String) -> ModalityClaim {
        return ModalityClaim(
            code: code,
            label: label,
            externalRef: "",
            allergy: "",
            weight: 0.0,
            status: ModalityClaimStatus.planned
        )
    }
}
