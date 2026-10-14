import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict shift score is in its life cycle.
    enum StrictShiftScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a strict shift score and its current status.
    final class StrictShiftScore {
        var code: String
        var title: String
        var active: Bool
        var patientRef: String
        var maximum: Double
        var discount: Double
        var threshold: Double
        var status: StrictShiftScoreStatus

        init(code: String, title: String, active: Bool, patientRef: String, maximum: Double, discount: Double, threshold: Double, status: StrictShiftScoreStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.patientRef = patientRef
            self.maximum = maximum
            self.discount = discount
            self.threshold = threshold
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

        func canMoveTo(_ next: StrictShiftScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == StrictShiftScoreStatus.active || next == StrictShiftScoreStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictShiftScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictShiftScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict shift score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((maximum - discount) * 100).rounded() / 100
        }

        func copyValue() -> StrictShiftScore {
            return StrictShiftScore(
                code: code,
                title: title,
                active: active,
                patientRef: patientRef,
                maximum: maximum,
                discount: discount,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict shift score in status draft.
    static func newStrictShiftScore(_ code: String, title: String) -> StrictShiftScore {
        return StrictShiftScore(
            code: code,
            title: title,
            active: false,
            patientRef: "",
            maximum: 0.0,
            discount: 0.0,
            threshold: 0.0,
            status: StrictShiftScoreStatus.draft
        )
    }
}
