import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality cycle is in its life cycle.
    enum ModalityCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One modality cycle, with what the planners need to act on it.
    final class ModalityCycle {
        var code: String
        var label: String
        var procedureCode: String
        var revision: Int
        var ceiling: Double
        var discount: Double
        var status: ModalityCycleStatus

        init(code: String, label: String, procedureCode: String, revision: Int, ceiling: Double, discount: Double, status: ModalityCycleStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.revision = revision
            self.ceiling = ceiling
            self.discount = discount
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

        func canMoveTo(_ next: ModalityCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == ModalityCycleStatus.retired
            case .validated:
                return next == ModalityCycleStatus.retired
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

        func moveTo(_ next: ModalityCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((discount - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ModalityCycle {
            return ModalityCycle(
                code: code,
                label: label,
                procedureCode: procedureCode,
                revision: revision,
                ceiling: ceiling,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality cycle in status created.
    static func newModalityCycle(_ code: String, label: String) -> ModalityCycle {
        return ModalityCycle(
            code: code,
            label: label,
            procedureCode: "",
            revision: 0,
            ceiling: 0.0,
            discount: 0.0,
            status: ModalityCycleStatus.created
        )
    }
}
