import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict rounding estimate is in its life cycle.
    enum StrictRoundingEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict rounding estimate, with what the planners need to act on it.
    final class StrictRoundingEstimate {
        var code: String
        var name: String
        var active: Bool
        var label: String
        var externalRef: String
        var quantity: Int
        var status: StrictRoundingEstimateStatus

        init(code: String, name: String, active: Bool, label: String, externalRef: String, quantity: Int, status: StrictRoundingEstimateStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.label = label
            self.externalRef = externalRef
            self.quantity = quantity
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

        func canMoveTo(_ next: StrictRoundingEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictRoundingEstimateStatus.queued || next == StrictRoundingEstimateStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictRoundingEstimateStatus.done || next == StrictRoundingEstimateStatus.failed
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

        func moveTo(_ next: StrictRoundingEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict rounding estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict rounding estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> StrictRoundingEstimate {
            return StrictRoundingEstimate(
                code: code,
                name: name,
                active: active,
                label: label,
                externalRef: externalRef,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict rounding estimate in status new.
    static func newStrictRoundingEstimate(_ code: String, name: String) -> StrictRoundingEstimate {
        return StrictRoundingEstimate(
            code: code,
            name: name,
            active: false,
            label: "",
            externalRef: "",
            quantity: 0,
            status: StrictRoundingEstimateStatus.new
        )
    }
}
