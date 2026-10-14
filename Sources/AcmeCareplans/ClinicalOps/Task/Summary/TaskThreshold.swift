import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task threshold is in its life cycle.
    enum TaskThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One task threshold, with what the planners need to act on it.
    final class TaskThreshold {
        var code: String
        var name: String
        var source: String
        var bed: String
        var copay: Double
        var ratio: Double
        var payer: String
        var status: TaskThresholdStatus

        init(code: String, name: String, source: String, bed: String, copay: Double, ratio: Double, payer: String, status: TaskThresholdStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.bed = bed
            self.copay = copay
            self.ratio = ratio
            self.payer = payer
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

        func canMoveTo(_ next: TaskThresholdStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TaskThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return (ratio * copay * 100).rounded() / 100
        }

        func copyValue() -> TaskThreshold {
            return TaskThreshold(
                code: code,
                name: name,
                source: source,
                bed: bed,
                copay: copay,
                ratio: ratio,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a task threshold in status created.
    static func newTaskThreshold(_ code: String, name: String) -> TaskThreshold {
        return TaskThreshold(
            code: code,
            name: name,
            source: "",
            bed: "",
            copay: 0.0,
            ratio: 0.0,
            payer: "",
            status: TaskThresholdStatus.created
        )
    }
}
