import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range checkpoint is in its life cycle.
    enum ReferenceRangeCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One reference range checkpoint, with what the planners need to act on it.
    final class ReferenceRangeCheckpoint {
        var code: String
        var name: String
        var durationMinutes: Int
        var sequence: Int
        var startsAt: Int
        var segment: String
        var discount: Double
        var floorValue: Double
        var visible: Bool
        var reviewer: String
        var status: ReferenceRangeCheckpointStatus

        init(code: String, name: String, durationMinutes: Int, sequence: Int, startsAt: Int, segment: String, discount: Double, floorValue: Double, visible: Bool, reviewer: String, status: ReferenceRangeCheckpointStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.startsAt = startsAt
            self.segment = segment
            self.discount = discount
            self.floorValue = floorValue
            self.visible = visible
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferenceRangeCheckpointStatus.running || next == ReferenceRangeCheckpointStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ReferenceRangeCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("reference range checkpoint") \(code)"
        }

        func effectiveExposure() -> Double {
            return (discount * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeCheckpoint {
            return ReferenceRangeCheckpoint(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                sequence: sequence,
                startsAt: startsAt,
                segment: segment,
                discount: discount,
                floorValue: floorValue,
                visible: visible,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a reference range checkpoint in status new.
    static func newReferenceRangeCheckpoint(_ code: String, name: String) -> ReferenceRangeCheckpoint {
        return ReferenceRangeCheckpoint(
            code: code,
            name: name,
            durationMinutes: 0,
            sequence: 0,
            startsAt: 0,
            segment: "",
            discount: 0.0,
            floorValue: 0.0,
            visible: false,
            reviewer: "",
            status: ReferenceRangeCheckpointStatus.new
        )
    }
}
