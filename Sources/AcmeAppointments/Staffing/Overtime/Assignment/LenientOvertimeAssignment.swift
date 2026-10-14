import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient overtime assignment is in its life cycle.
    enum LenientOvertimeAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient overtime assignment, with what the planners need to act on it.
    final class LenientOvertimeAssignment {
        var code: String
        var title: String
        var margin: Double
        var refills: Int
        var acuity: Int
        var weight: Double
        var status: LenientOvertimeAssignmentStatus

        init(code: String, title: String, margin: Double, refills: Int, acuity: Int, weight: Double, status: LenientOvertimeAssignmentStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.refills = refills
            self.acuity = acuity
            self.weight = weight
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

        func canMoveTo(_ next: LenientOvertimeAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientOvertimeAssignmentStatus.running || next == LenientOvertimeAssignmentStatus.done
            case .queued:
                return next == LenientOvertimeAssignmentStatus.failed
            case .running:
                return next == LenientOvertimeAssignmentStatus.done
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

        func moveTo(_ next: LenientOvertimeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient overtime assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient overtime assignment") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(refills) * weight * 100).rounded() / 100
        }

        func copyValue() -> LenientOvertimeAssignment {
            return LenientOvertimeAssignment(
                code: code,
                title: title,
                margin: margin,
                refills: refills,
                acuity: acuity,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient overtime assignment in status new.
    static func newLenientOvertimeAssignment(_ code: String, title: String) -> LenientOvertimeAssignment {
        return LenientOvertimeAssignment(
            code: code,
            title: title,
            margin: 0.0,
            refills: 0,
            acuity: 0,
            weight: 0.0,
            status: LenientOvertimeAssignmentStatus.new
        )
    }
}
