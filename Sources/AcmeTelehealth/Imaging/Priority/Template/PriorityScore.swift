import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority score is in its life cycle.
    enum PriorityScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A priority score. Its code is unique within a tenant.
    final class PriorityScore {
        var code: String
        var title: String
        var summary: String
        var diagnosisCode: String
        var copay: Double
        var rate: Double
        var margin: Double
        var status: PriorityScoreStatus

        init(code: String, title: String, summary: String, diagnosisCode: String, copay: Double, rate: Double, margin: Double, status: PriorityScoreStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.rate = rate
            self.margin = margin
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

        func canMoveTo(_ next: PriorityScoreStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PriorityScoreStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PriorityScoreStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((rate - margin) * 100).rounded() / 100
        }

        func copyValue() -> PriorityScore {
            return PriorityScore(
                code: code,
                title: title,
                summary: summary,
                diagnosisCode: diagnosisCode,
                copay: copay,
                rate: rate,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a priority score in status idle.
    static func newPriorityScore(_ code: String, title: String) -> PriorityScore {
        return PriorityScore(
            code: code,
            title: title,
            summary: "",
            diagnosisCode: "",
            copay: 0.0,
            rate: 0.0,
            margin: 0.0,
            status: PriorityScoreStatus.idle
        )
    }
}
