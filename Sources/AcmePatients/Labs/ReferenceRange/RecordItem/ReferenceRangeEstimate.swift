import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range estimate is in its life cycle.
    enum ReferenceRangeEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A reference range estimate as the reference range team keeps it.
    final class ReferenceRangeEstimate {
        var code: String
        var title: String
        var active: Bool
        var procedureCode: String
        var amount: Double
        var status: ReferenceRangeEstimateStatus

        init(code: String, title: String, active: Bool, procedureCode: String, amount: Double, status: ReferenceRangeEstimateStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.procedureCode = procedureCode
            self.amount = amount
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

        func canMoveTo(_ next: ReferenceRangeEstimateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferenceRangeEstimateStatus.stopped
            case .ready:
                return next == ReferenceRangeEstimateStatus.draining || next == ReferenceRangeEstimateStatus.stopped
            case .draining:
                return next == ReferenceRangeEstimateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ReferenceRangeEstimate {
            return ReferenceRangeEstimate(
                code: code,
                title: title,
                active: active,
                procedureCode: procedureCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a reference range estimate in status idle.
    static func newReferenceRangeEstimate(_ code: String, title: String) -> ReferenceRangeEstimate {
        return ReferenceRangeEstimate(
            code: code,
            title: title,
            active: false,
            procedureCode: "",
            amount: 0.0,
            status: ReferenceRangeEstimateStatus.idle
        )
    }
}
