import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist window is in its life cycle.
    enum WorklistWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One worklist window, with what the planners need to act on it.
    final class WorklistWindow {
        var code: String
        var title: String
        var endsAt: Int
        var limit: Int
        var bed: String
        var externalRef: String
        var sequence: Int
        var patientRef: String
        var status: WorklistWindowStatus

        init(code: String, title: String, endsAt: Int, limit: Int, bed: String, externalRef: String, sequence: Int, patientRef: String, status: WorklistWindowStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.limit = limit
            self.bed = bed
            self.externalRef = externalRef
            self.sequence = sequence
            self.patientRef = patientRef
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

        func canMoveTo(_ next: WorklistWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WorklistWindowStatus.published
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

        func moveTo(_ next: WorklistWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((Double(sequence) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistWindow {
            return WorklistWindow(
                code: code,
                title: title,
                endsAt: endsAt,
                limit: limit,
                bed: bed,
                externalRef: externalRef,
                sequence: sequence,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist window in status created.
    static func newWorklistWindow(_ code: String, title: String) -> WorklistWindow {
        return WorklistWindow(
            code: code,
            title: title,
            endsAt: 0,
            limit: 0,
            bed: "",
            externalRef: "",
            sequence: 0,
            patientRef: "",
            status: WorklistWindowStatus.created
        )
    }
}
