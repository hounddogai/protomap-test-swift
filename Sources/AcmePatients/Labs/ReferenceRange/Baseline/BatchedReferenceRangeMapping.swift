import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched reference range mapping is in its life cycle.
    enum BatchedReferenceRangeMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched reference range mapping. Its code is unique within a tenant.
    final class BatchedReferenceRangeMapping {
        var code: String
        var name: String
        var sequence: Int
        var priority: Int
        var locale: String
        var createdAt: Int
        var refills: Int
        var pinned: Bool
        var status: BatchedReferenceRangeMappingStatus

        init(code: String, name: String, sequence: Int, priority: Int, locale: String, createdAt: Int, refills: Int, pinned: Bool, status: BatchedReferenceRangeMappingStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.priority = priority
            self.locale = locale
            self.createdAt = createdAt
            self.refills = refills
            self.pinned = pinned
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

        func canMoveTo(_ next: BatchedReferenceRangeMappingStatus) -> Bool {
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
                return next == BatchedReferenceRangeMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedReferenceRangeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched reference range mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched reference range mapping") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(priority) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedReferenceRangeMapping {
            return BatchedReferenceRangeMapping(
                code: code,
                name: name,
                sequence: sequence,
                priority: priority,
                locale: locale,
                createdAt: createdAt,
                refills: refills,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched reference range mapping in status planned.
    static func newBatchedReferenceRangeMapping(_ code: String, name: String) -> BatchedReferenceRangeMapping {
        return BatchedReferenceRangeMapping(
            code: code,
            name: name,
            sequence: 0,
            priority: 0,
            locale: "",
            createdAt: 0,
            refills: 0,
            pinned: false,
            status: BatchedReferenceRangeMappingStatus.planned
        )
    }
}
