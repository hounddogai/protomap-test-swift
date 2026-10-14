import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling alert bundle is in its life cycle.
    enum RollingAlertBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling alert bundle as the alert team keeps it.
    final class RollingAlertBundle {
        var code: String
        var name: String
        var attributes: [String: String]
        var procedureCode: String
        var region: String
        var amount: Double
        var status: RollingAlertBundleStatus

        init(code: String, name: String, attributes: [String: String], procedureCode: String, region: String, amount: Double, status: RollingAlertBundleStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.procedureCode = procedureCode
            self.region = region
            self.amount = amount
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

        func canMoveTo(_ next: RollingAlertBundleStatus) -> Bool {
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
                return next == RollingAlertBundleStatus.expired
            case .revoked:
                return next == RollingAlertBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAlertBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling alert bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RollingAlertBundle {
            return RollingAlertBundle(
                code: code,
                name: name,
                attributes: attributes,
                procedureCode: procedureCode,
                region: region,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling alert bundle in status requested.
    static func newRollingAlertBundle(_ code: String, name: String) -> RollingAlertBundle {
        return RollingAlertBundle(
            code: code,
            name: name,
            attributes: [:],
            procedureCode: "",
            region: "",
            amount: 0.0,
            status: RollingAlertBundleStatus.requested
        )
    }
}
