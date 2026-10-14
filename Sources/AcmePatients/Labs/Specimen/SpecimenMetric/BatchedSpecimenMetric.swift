import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched specimen metric is in its life cycle.
    enum BatchedSpecimenMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched specimen metric, with what the planners need to act on it.
    final class BatchedSpecimenMetric {
        var code: String
        var label: String
        var facility: String
        var sequence: Int
        var visitMinutes: Int
        var checksum: String
        var description: String
        var limit: Int
        var version: Int
        var archived: Bool
        var rate: Double
        var status: BatchedSpecimenMetricStatus

        init(code: String, label: String, facility: String, sequence: Int, visitMinutes: Int, checksum: String, description: String, limit: Int, version: Int, archived: Bool, rate: Double, status: BatchedSpecimenMetricStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.sequence = sequence
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.description = description
            self.limit = limit
            self.version = version
            self.archived = archived
            self.rate = rate
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

        func canMoveTo(_ next: BatchedSpecimenMetricStatus) -> Bool {
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
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BatchedSpecimenMetricStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSpecimenMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched specimen metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((Double(limit) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSpecimenMetric {
            return BatchedSpecimenMetric(
                code: code,
                label: label,
                facility: facility,
                sequence: sequence,
                visitMinutes: visitMinutes,
                checksum: checksum,
                description: description,
                limit: limit,
                version: version,
                archived: archived,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched specimen metric in status planned.
    static func newBatchedSpecimenMetric(_ code: String, label: String) -> BatchedSpecimenMetric {
        return BatchedSpecimenMetric(
            code: code,
            label: label,
            facility: "",
            sequence: 0,
            visitMinutes: 0,
            checksum: "",
            description: "",
            limit: 0,
            version: 0,
            archived: false,
            rate: 0.0,
            status: BatchedSpecimenMetricStatus.planned
        )
    }
}
