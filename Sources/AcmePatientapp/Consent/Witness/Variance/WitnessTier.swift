import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness tier is in its life cycle.
    enum WitnessTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A witness tier as the witness team keeps it.
    final class WitnessTier {
        var code: String
        var name: String
        var ceiling: Double
        var unit: String
        var bed: String
        var phone: String
        var cost: Double
        var status: WitnessTierStatus

        init(code: String, name: String, ceiling: Double, unit: String, bed: String, phone: String, cost: Double, status: WitnessTierStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.unit = unit
            self.bed = bed
            self.phone = phone
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WitnessTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((cost - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> WitnessTier {
            return WitnessTier(
                code: code,
                name: name,
                ceiling: ceiling,
                unit: unit,
                bed: bed,
                phone: phone,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a witness tier in status created.
    static func newWitnessTier(_ code: String, name: String) -> WitnessTier {
        return WitnessTier(
            code: code,
            name: name,
            ceiling: 0.0,
            unit: "",
            bed: "",
            phone: "",
            cost: 0.0,
            status: WitnessTierStatus.created
        )
    }
}
