import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled reference range segment is in its life cycle.
    enum ScheduledReferenceRangeSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled reference range segment and its current status.
    final class ScheduledReferenceRangeSegment {
        var code: String
        var name: String
        var maximum: Double
        var visitMinutes: Int
        var weight: Double
        var ward: String
        var approved: Bool
        var payer: String
        var dosageMg: Double
        var status: ScheduledReferenceRangeSegmentStatus

        init(code: String, name: String, maximum: Double, visitMinutes: Int, weight: Double, ward: String, approved: Bool, payer: String, dosageMg: Double, status: ScheduledReferenceRangeSegmentStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.ward = ward
            self.approved = approved
            self.payer = payer
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ScheduledReferenceRangeSegmentStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledReferenceRangeSegmentStatus.queued || next == ScheduledReferenceRangeSegmentStatus.done
            case .queued:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: ScheduledReferenceRangeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled reference range segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled reference range segment") \(code)"
        }

        func weightedLoad() -> Double {
            return (maximum * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReferenceRangeSegment {
            return ScheduledReferenceRangeSegment(
                code: code,
                name: name,
                maximum: maximum,
                visitMinutes: visitMinutes,
                weight: weight,
                ward: ward,
                approved: approved,
                payer: payer,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled reference range segment in status new.
    static func newScheduledReferenceRangeSegment(_ code: String, name: String) -> ScheduledReferenceRangeSegment {
        return ScheduledReferenceRangeSegment(
            code: code,
            name: name,
            maximum: 0.0,
            visitMinutes: 0,
            weight: 0.0,
            ward: "",
            approved: false,
            payer: "",
            dosageMg: 0.0,
            status: ScheduledReferenceRangeSegmentStatus.new
        )
    }
}
