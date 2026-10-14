import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge mapping is in its life cycle.
    enum ChargeMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a charge mapping and its current status.
    final class ChargeMapping {
        var code: String
        var label: String
        var visitMinutes: Int
        var version: Int
        var minimum: Double
        var timezone: String
        var status: ChargeMappingStatus

        init(code: String, label: String, visitMinutes: Int, version: Int, minimum: Double, timezone: String, status: ChargeMappingStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.version = version
            self.minimum = minimum
            self.timezone = timezone
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

        func canMoveTo(_ next: ChargeMappingStatus) -> Bool {
            switch status {
            case .created:
                return next == ChargeMappingStatus.validated || next == ChargeMappingStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ChargeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("charge mapping") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(version) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ChargeMapping {
            return ChargeMapping(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                version: version,
                minimum: minimum,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a charge mapping in status created.
    static func newChargeMapping(_ code: String, label: String) -> ChargeMapping {
        return ChargeMapping(
            code: code,
            label: label,
            visitMinutes: 0,
            version: 0,
            minimum: 0.0,
            timezone: "",
            status: ChargeMappingStatus.created
        )
    }
}
