import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient float pool variance is in its life cycle.
    enum LenientFloatPoolVarianceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient float pool variance, with what the planners need to act on it.
    final class LenientFloatPoolVariance {
        var code: String
        var title: String
        var facility: String
        var budget: Double
        var reviewer: String
        var notes: String
        var floorValue: Double
        var status: LenientFloatPoolVarianceStatus

        init(code: String, title: String, facility: String, budget: Double, reviewer: String, notes: String, floorValue: Double, status: LenientFloatPoolVarianceStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.budget = budget
            self.reviewer = reviewer
            self.notes = notes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LenientFloatPoolVarianceStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientFloatPoolVarianceStatus.draining
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientFloatPoolVarianceStatus.draining || next == LenientFloatPoolVarianceStatus.stopped
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

        func moveTo(_ next: LenientFloatPoolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient float pool variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((budget + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LenientFloatPoolVariance {
            return LenientFloatPoolVariance(
                code: code,
                title: title,
                facility: facility,
                budget: budget,
                reviewer: reviewer,
                notes: notes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient float pool variance in status idle.
    static func newLenientFloatPoolVariance(_ code: String, title: String) -> LenientFloatPoolVariance {
        return LenientFloatPoolVariance(
            code: code,
            title: title,
            facility: "",
            budget: 0.0,
            reviewer: "",
            notes: "",
            floorValue: 0.0,
            status: LenientFloatPoolVarianceStatus.idle
        )
    }
}
