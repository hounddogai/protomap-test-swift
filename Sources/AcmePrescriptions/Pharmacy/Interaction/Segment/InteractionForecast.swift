import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction forecast is in its life cycle.
    enum InteractionForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A interaction forecast. Its code is unique within a tenant.
    final class InteractionForecast {
        var code: String
        var title: String
        var endsAt: Int
        var notes: String
        var dosageMg: Double
        var capacity: Int
        var description: String
        var externalRef: String
        var active: Bool
        var windowDays: Int
        var quantity: Int
        var status: InteractionForecastStatus

        init(code: String, title: String, endsAt: Int, notes: String, dosageMg: Double, capacity: Int, description: String, externalRef: String, active: Bool, windowDays: Int, quantity: Int, status: InteractionForecastStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.notes = notes
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.description = description
            self.externalRef = externalRef
            self.active = active
            self.windowDays = windowDays
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

        func canMoveTo(_ next: InteractionForecastStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: InteractionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("interaction forecast") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> InteractionForecast {
            return InteractionForecast(
                code: code,
                title: title,
                endsAt: endsAt,
                notes: notes,
                dosageMg: dosageMg,
                capacity: capacity,
                description: description,
                externalRef: externalRef,
                active: active,
                windowDays: windowDays,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction forecast in status new.
    static func newInteractionForecast(_ code: String, title: String) -> InteractionForecast {
        return InteractionForecast(
            code: code,
            title: title,
            endsAt: 0,
            notes: "",
            dosageMg: 0.0,
            capacity: 0,
            description: "",
            externalRef: "",
            active: false,
            windowDays: 0,
            quantity: 0,
            status: InteractionForecastStatus.new
        )
    }
}
