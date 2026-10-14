import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range window is in its life cycle.
    enum LenientReferenceRangeWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient reference range window. Its code is unique within a tenant.
    final class LenientReferenceRangeWindow {
        var code: String
        var name: String
        var segment: String
        var rate: Double
        var specialty: String
        var amount: Double
        var status: LenientReferenceRangeWindowStatus

        init(code: String, name: String, segment: String, rate: Double, specialty: String, amount: Double, status: LenientReferenceRangeWindowStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.rate = rate
            self.specialty = specialty
            self.amount = amount
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

        func canMoveTo(_ next: LenientReferenceRangeWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientReferenceRangeWindowStatus.scheduled || next == LenientReferenceRangeWindowStatus.cancelled
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

        func moveTo(_ next: LenientReferenceRangeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((rate + amount) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeWindow {
            return LenientReferenceRangeWindow(
                code: code,
                name: name,
                segment: segment,
                rate: rate,
                specialty: specialty,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient reference range window in status planned.
    static func newLenientReferenceRangeWindow(_ code: String, name: String) -> LenientReferenceRangeWindow {
        return LenientReferenceRangeWindow(
            code: code,
            name: name,
            segment: "",
            rate: 0.0,
            specialty: "",
            amount: 0.0,
            status: LenientReferenceRangeWindowStatus.planned
        )
    }
}
