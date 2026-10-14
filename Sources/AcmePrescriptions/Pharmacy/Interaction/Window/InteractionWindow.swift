import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction window is in its life cycle.
    enum InteractionWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A interaction window as the interaction team keeps it.
    final class InteractionWindow {
        var code: String
        var title: String
        var locale: String
        var threshold: Double
        var quantity: Int
        var bed: String
        var score: Double
        var status: InteractionWindowStatus

        init(code: String, title: String, locale: String, threshold: Double, quantity: Int, bed: String, score: Double, status: InteractionWindowStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.threshold = threshold
            self.quantity = quantity
            self.bed = bed
            self.score = score
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

        func canMoveTo(_ next: InteractionWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionWindowStatus.queued || next == InteractionWindowStatus.failed
            case .queued:
                return next == InteractionWindowStatus.running || next == InteractionWindowStatus.done
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

        func moveTo(_ next: InteractionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((Double(quantity) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> InteractionWindow {
            return InteractionWindow(
                code: code,
                title: title,
                locale: locale,
                threshold: threshold,
                quantity: quantity,
                bed: bed,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a interaction window in status new.
    static func newInteractionWindow(_ code: String, title: String) -> InteractionWindow {
        return InteractionWindow(
            code: code,
            title: title,
            locale: "",
            threshold: 0.0,
            quantity: 0,
            bed: "",
            score: 0.0,
            status: InteractionWindowStatus.new
        )
    }
}
