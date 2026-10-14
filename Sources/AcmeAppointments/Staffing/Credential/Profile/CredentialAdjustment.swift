import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential adjustment is in its life cycle.
    enum CredentialAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A credential adjustment as the credential team keeps it.
    final class CredentialAdjustment {
        var code: String
        var name: String
        var maximum: Double
        var pinned: Bool
        var summary: String
        var weight: Double
        var currency: String
        var discount: Double
        var facility: String
        var floorValue: Double
        var durationMinutes: Int
        var status: CredentialAdjustmentStatus

        init(code: String, name: String, maximum: Double, pinned: Bool, summary: String, weight: Double, currency: String, discount: Double, facility: String, floorValue: Double, durationMinutes: Int, status: CredentialAdjustmentStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.pinned = pinned
            self.summary = summary
            self.weight = weight
            self.currency = currency
            self.discount = discount
            self.facility = facility
            self.floorValue = floorValue
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CredentialAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential adjustment") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(durationMinutes) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> CredentialAdjustment {
            return CredentialAdjustment(
                code: code,
                name: name,
                maximum: maximum,
                pinned: pinned,
                summary: summary,
                weight: weight,
                currency: currency,
                discount: discount,
                facility: facility,
                floorValue: floorValue,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential adjustment in status planned.
    static func newCredentialAdjustment(_ code: String, name: String) -> CredentialAdjustment {
        return CredentialAdjustment(
            code: code,
            name: name,
            maximum: 0.0,
            pinned: false,
            summary: "",
            weight: 0.0,
            currency: "",
            discount: 0.0,
            facility: "",
            floorValue: 0.0,
            durationMinutes: 0,
            status: CredentialAdjustmentStatus.planned
        )
    }
}
