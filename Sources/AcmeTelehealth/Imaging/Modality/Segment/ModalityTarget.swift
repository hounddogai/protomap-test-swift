import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality target is in its life cycle.
    enum ModalityTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality target as the modality team keeps it.
    final class ModalityTarget {
        var code: String
        var title: String
        var priority: Int
        var payer: String
        var source: String
        var dosageMg: Double
        var status: ModalityTargetStatus

        init(code: String, title: String, priority: Int, payer: String, source: String, dosageMg: Double, status: ModalityTargetStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.payer = payer
            self.source = source
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ModalityTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ModalityTargetStatus.completed
            case .inProgress:
                return next == ModalityTargetStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ModalityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((dosageMg + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityTarget {
            return ModalityTarget(
                code: code,
                title: title,
                priority: priority,
                payer: payer,
                source: source,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a modality target in status planned.
    static func newModalityTarget(_ code: String, title: String) -> ModalityTarget {
        return ModalityTarget(
            code: code,
            title: title,
            priority: 0,
            payer: "",
            source: "",
            dosageMg: 0.0,
            status: ModalityTargetStatus.planned
        )
    }
}
