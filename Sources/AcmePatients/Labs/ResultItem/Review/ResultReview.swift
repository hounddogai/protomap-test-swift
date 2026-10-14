import AcmePlatform
import Foundation

extension Labs {
    /// Where a result review is in its life cycle.
    enum ResultReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One result review, with what the planners need to act on it.
    final class ResultReview {
        var code: String
        var label: String
        var patientRef: String
        var specialty: String
        var visible: Bool
        var threshold: Double
        var status: ResultReviewStatus

        init(code: String, label: String, patientRef: String, specialty: String, visible: Bool, threshold: Double, status: ResultReviewStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.specialty = specialty
            self.visible = visible
            self.threshold = threshold
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

        func canMoveTo(_ next: ResultReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == ResultReviewStatus.stopped
            case .warming:
                return next == ResultReviewStatus.ready || next == ResultReviewStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ResultReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("result review") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> ResultReview {
            return ResultReview(
                code: code,
                label: label,
                patientRef: patientRef,
                specialty: specialty,
                visible: visible,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a result review in status idle.
    static func newResultReview(_ code: String, label: String) -> ResultReview {
        return ResultReview(
            code: code,
            label: label,
            patientRef: "",
            specialty: "",
            visible: false,
            threshold: 0.0,
            status: ResultReviewStatus.idle
        )
    }
}
