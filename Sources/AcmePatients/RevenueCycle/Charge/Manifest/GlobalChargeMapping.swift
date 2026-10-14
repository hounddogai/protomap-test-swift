import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global charge mapping is in its life cycle.
    enum GlobalChargeMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global charge mapping as the charge team keeps it.
    final class GlobalChargeMapping {
        var code: String
        var name: String
        var locale: String
        var facility: String
        var patientRef: String
        var attempts: Int
        var region: String
        var retries: Int
        var status: GlobalChargeMappingStatus

        init(code: String, name: String, locale: String, facility: String, patientRef: String, attempts: Int, region: String, retries: Int, status: GlobalChargeMappingStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.facility = facility
            self.patientRef = patientRef
            self.attempts = attempts
            self.region = region
            self.retries = retries
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

        func canMoveTo(_ next: GlobalChargeMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalChargeMappingStatus.stopped
            case .warming:
                return next == GlobalChargeMappingStatus.draining || next == GlobalChargeMappingStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalChargeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global charge mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return (Double(attempts) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> GlobalChargeMapping {
            return GlobalChargeMapping(
                code: code,
                name: name,
                locale: locale,
                facility: facility,
                patientRef: patientRef,
                attempts: attempts,
                region: region,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global charge mapping in status idle.
    static func newGlobalChargeMapping(_ code: String, name: String) -> GlobalChargeMapping {
        return GlobalChargeMapping(
            code: code,
            name: name,
            locale: "",
            facility: "",
            patientRef: "",
            attempts: 0,
            region: "",
            retries: 0,
            status: GlobalChargeMappingStatus.idle
        )
    }
}
