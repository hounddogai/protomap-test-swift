import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality forecast is in its life cycle.
    enum ModalityForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A modality forecast. Its code is unique within a tenant.
    final class ModalityForecast {
        var code: String
        var name: String
        var priority: Int
        var acuity: Int
        var floorValue: Double
        var active: Bool
        var ward: String
        var notes: String
        var graceDays: Int
        var status: ModalityForecastStatus

        init(code: String, name: String, priority: Int, acuity: Int, floorValue: Double, active: Bool, ward: String, notes: String, graceDays: Int, status: ModalityForecastStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.acuity = acuity
            self.floorValue = floorValue
            self.active = active
            self.ward = ward
            self.notes = notes
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ModalityForecastStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ModalityForecastStatus.draining || next == ModalityForecastStatus.stopped
            case .ready:
                return next == ModalityForecastStatus.draining || next == ModalityForecastStatus.stopped
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

        func moveTo(_ next: ModalityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((Double(graceDays) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ModalityForecast {
            return ModalityForecast(
                code: code,
                name: name,
                priority: priority,
                acuity: acuity,
                floorValue: floorValue,
                active: active,
                ward: ward,
                notes: notes,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a modality forecast in status idle.
    static func newModalityForecast(_ code: String, name: String) -> ModalityForecast {
        return ModalityForecast(
            code: code,
            name: name,
            priority: 0,
            acuity: 0,
            floorValue: 0.0,
            active: false,
            ward: "",
            notes: "",
            graceDays: 0,
            status: ModalityForecastStatus.idle
        )
    }
}
