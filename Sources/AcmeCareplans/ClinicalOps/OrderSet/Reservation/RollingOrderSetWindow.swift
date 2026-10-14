import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling order set window is in its life cycle.
    enum RollingOrderSetWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling order set window, with what the planners need to act on it.
    final class RollingOrderSetWindow {
        var code: String
        var name: String
        var attempts: Int
        var quantity: Int
        var currency: String
        var sequence: Int
        var margin: Double
        var category: String
        var status: RollingOrderSetWindowStatus

        init(code: String, name: String, attempts: Int, quantity: Int, currency: String, sequence: Int, margin: Double, category: String, status: RollingOrderSetWindowStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.quantity = quantity
            self.currency = currency
            self.sequence = sequence
            self.margin = margin
            self.category = category
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

        func canMoveTo(_ next: RollingOrderSetWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingOrderSetWindowStatus.queued || next == RollingOrderSetWindowStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingOrderSetWindowStatus.done || next == RollingOrderSetWindowStatus.failed
            case .done:
                return next == RollingOrderSetWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingOrderSetWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling order set window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling order set window") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) - margin) * 100).rounded() / 100
        }

        func copyValue() -> RollingOrderSetWindow {
            return RollingOrderSetWindow(
                code: code,
                name: name,
                attempts: attempts,
                quantity: quantity,
                currency: currency,
                sequence: sequence,
                margin: margin,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling order set window in status new.
    static func newRollingOrderSetWindow(_ code: String, name: String) -> RollingOrderSetWindow {
        return RollingOrderSetWindow(
            code: code,
            name: name,
            attempts: 0,
            quantity: 0,
            currency: "",
            sequence: 0,
            margin: 0.0,
            category: "",
            status: RollingOrderSetWindowStatus.new
        )
    }
}
