import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled reference range record is in its life cycle.
    enum ScheduledReferenceRangeRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled reference range record. Its code is unique within a tenant.
    final class ScheduledReferenceRangeRecord {
        var code: String
        var label: String
        var weight: Double
        var region: String
        var rate: Double
        var category: String
        var floorValue: Double
        var status: ScheduledReferenceRangeRecordStatus

        init(code: String, label: String, weight: Double, region: String, rate: Double, category: String, floorValue: Double, status: ScheduledReferenceRangeRecordStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.region = region
            self.rate = rate
            self.category = category
            self.floorValue = floorValue
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

        func canMoveTo(_ next: ScheduledReferenceRangeRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledReferenceRangeRecordStatus.inProgress || next == ScheduledReferenceRangeRecordStatus.completed
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
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledReferenceRangeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled reference range record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((weight + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReferenceRangeRecord {
            return ScheduledReferenceRangeRecord(
                code: code,
                label: label,
                weight: weight,
                region: region,
                rate: rate,
                category: category,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled reference range record in status planned.
    static func newScheduledReferenceRangeRecord(_ code: String, label: String) -> ScheduledReferenceRangeRecord {
        return ScheduledReferenceRangeRecord(
            code: code,
            label: label,
            weight: 0.0,
            region: "",
            rate: 0.0,
            category: "",
            floorValue: 0.0,
            status: ScheduledReferenceRangeRecordStatus.planned
        )
    }
}
