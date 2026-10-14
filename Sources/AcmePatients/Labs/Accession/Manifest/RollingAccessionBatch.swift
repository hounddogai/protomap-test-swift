import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession batch is in its life cycle.
    enum RollingAccessionBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling accession batch as the accession team keeps it.
    final class RollingAccessionBatch {
        var code: String
        var title: String
        var maximum: Double
        var segment: String
        var patientRef: String
        var margin: Double
        var status: RollingAccessionBatchStatus

        init(code: String, title: String, maximum: Double, segment: String, patientRef: String, margin: Double, status: RollingAccessionBatchStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.segment = segment
            self.patientRef = patientRef
            self.margin = margin
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

        func canMoveTo(_ next: RollingAccessionBatchStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingAccessionBatchStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingAccessionBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((margin - maximum) * 100).rounded() / 100
        }

        func copyValue() -> RollingAccessionBatch {
            return RollingAccessionBatch(
                code: code,
                title: title,
                maximum: maximum,
                segment: segment,
                patientRef: patientRef,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling accession batch in status idle.
    static func newRollingAccessionBatch(_ code: String, title: String) -> RollingAccessionBatch {
        return RollingAccessionBatch(
            code: code,
            title: title,
            maximum: 0.0,
            segment: "",
            patientRef: "",
            margin: 0.0,
            status: RollingAccessionBatchStatus.idle
        )
    }
}
