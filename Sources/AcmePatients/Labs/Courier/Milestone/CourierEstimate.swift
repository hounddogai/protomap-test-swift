import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier estimate is in its life cycle.
    enum CourierEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a courier estimate and its current status.
    final class CourierEstimate {
        var code: String
        var title: String
        var quantity: Int
        var attempts: Int
        var source: String
        var minimum: Double
        var refills: Int
        var margin: Double
        var status: CourierEstimateStatus

        init(code: String, title: String, quantity: Int, attempts: Int, source: String, minimum: Double, refills: Int, margin: Double, status: CourierEstimateStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.attempts = attempts
            self.source = source
            self.minimum = minimum
            self.refills = refills
            self.margin = margin
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

        func canMoveTo(_ next: CourierEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == CourierEstimateStatus.running || next == CourierEstimateStatus.failed
            case .queued:
                return next == CourierEstimateStatus.done
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: CourierEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return ((Double(attempts) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> CourierEstimate {
            return CourierEstimate(
                code: code,
                title: title,
                quantity: quantity,
                attempts: attempts,
                source: source,
                minimum: minimum,
                refills: refills,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a courier estimate in status new.
    static func newCourierEstimate(_ code: String, title: String) -> CourierEstimate {
        return CourierEstimate(
            code: code,
            title: title,
            quantity: 0,
            attempts: 0,
            source: "",
            minimum: 0.0,
            refills: 0,
            margin: 0.0,
            status: CourierEstimateStatus.new
        )
    }
}
