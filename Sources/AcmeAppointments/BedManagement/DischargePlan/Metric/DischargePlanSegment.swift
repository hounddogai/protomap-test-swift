import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan segment is in its life cycle.
    enum DischargePlanSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A discharge plan segment. Its code is unique within a tenant.
    final class DischargePlanSegment {
        var code: String
        var name: String
        var clinicianID: String
        var floorValue: Double
        var reviewer: String
        var status: DischargePlanSegmentStatus

        init(code: String, name: String, clinicianID: String, floorValue: Double, reviewer: String, status: DischargePlanSegmentStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.reviewer = reviewer
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

        func canMoveTo(_ next: DischargePlanSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == DischargePlanSegmentStatus.published || next == DischargePlanSegmentStatus.retired
            case .validated:
                return next == DischargePlanSegmentStatus.published
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

        func moveTo(_ next: DischargePlanSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("discharge plan segment") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> DischargePlanSegment {
            return DischargePlanSegment(
                code: code,
                name: name,
                clinicianID: clinicianID,
                floorValue: floorValue,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan segment in status created.
    static func newDischargePlanSegment(_ code: String, name: String) -> DischargePlanSegment {
        return DischargePlanSegment(
            code: code,
            name: name,
            clinicianID: "",
            floorValue: 0.0,
            reviewer: "",
            status: DischargePlanSegmentStatus.created
        )
    }
}
