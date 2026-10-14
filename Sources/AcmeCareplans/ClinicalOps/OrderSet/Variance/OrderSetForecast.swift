import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set forecast is in its life cycle.
    enum OrderSetForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A order set forecast. Its code is unique within a tenant.
    final class OrderSetForecast {
        var code: String
        var label: String
        var checksum: String
        var pinned: Bool
        var graceDays: Int
        var allergy: String
        var phone: String
        var status: OrderSetForecastStatus

        init(code: String, label: String, checksum: String, pinned: Bool, graceDays: Int, allergy: String, phone: String, status: OrderSetForecastStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.pinned = pinned
            self.graceDays = graceDays
            self.allergy = allergy
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OrderSetForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> OrderSetForecast {
            return OrderSetForecast(
                code: code,
                label: label,
                checksum: checksum,
                pinned: pinned,
                graceDays: graceDays,
                allergy: allergy,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set forecast in status requested.
    static func newOrderSetForecast(_ code: String, label: String) -> OrderSetForecast {
        return OrderSetForecast(
            code: code,
            label: label,
            checksum: "",
            pinned: false,
            graceDays: 0,
            allergy: "",
            phone: "",
            status: OrderSetForecastStatus.requested
        )
    }
}
