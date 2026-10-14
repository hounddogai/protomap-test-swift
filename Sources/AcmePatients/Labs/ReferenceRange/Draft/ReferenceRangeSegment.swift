import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range segment is in its life cycle.
    enum ReferenceRangeSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a reference range segment and its current status.
    final class ReferenceRangeSegment {
        var code: String
        var name: String
        var specialty: String
        var retries: Int
        var acuity: Int
        var segment: String
        var visitMinutes: Int
        var active: Bool
        var status: ReferenceRangeSegmentStatus

        init(code: String, name: String, specialty: String, retries: Int, acuity: Int, segment: String, visitMinutes: Int, active: Bool, status: ReferenceRangeSegmentStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.retries = retries
            self.acuity = acuity
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferenceRangeSegmentStatus.pending
            case .pending:
                return next == ReferenceRangeSegmentStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ReferenceRangeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("reference range segment") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(acuity) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeSegment {
            return ReferenceRangeSegment(
                code: code,
                name: name,
                specialty: specialty,
                retries: retries,
                acuity: acuity,
                segment: segment,
                visitMinutes: visitMinutes,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a reference range segment in status draft.
    static func newReferenceRangeSegment(_ code: String, name: String) -> ReferenceRangeSegment {
        return ReferenceRangeSegment(
            code: code,
            name: name,
            specialty: "",
            retries: 0,
            acuity: 0,
            segment: "",
            visitMinutes: 0,
            active: false,
            status: ReferenceRangeSegmentStatus.draft
        )
    }
}
