import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession record is in its life cycle.
    enum AccessionRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One accession record, with what the planners need to act on it.
    final class AccessionRecord {
        var code: String
        var name: String
        var label: String
        var threshold: Double
        var priority: Int
        var status: AccessionRecordStatus

        init(code: String, name: String, label: String, threshold: Double, priority: Int, status: AccessionRecordStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.threshold = threshold
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AccessionRecordStatus.ready
            case .ready:
                return next == AccessionRecordStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AccessionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(priority) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> AccessionRecord {
            return AccessionRecord(
                code: code,
                name: name,
                label: label,
                threshold: threshold,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession record in status idle.
    static func newAccessionRecord(_ code: String, name: String) -> AccessionRecord {
        return AccessionRecord(
            code: code,
            name: name,
            label: "",
            threshold: 0.0,
            priority: 0,
            status: AccessionRecordStatus.idle
        )
    }
}
