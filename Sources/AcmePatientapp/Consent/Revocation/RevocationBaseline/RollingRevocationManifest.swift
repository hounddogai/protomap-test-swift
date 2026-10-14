import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling revocation manifest is in its life cycle.
    enum RollingRevocationManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling revocation manifest and its current status.
    final class RollingRevocationManifest {
        var code: String
        var name: String
        var floorValue: Double
        var payer: String
        var country: String
        var status: RollingRevocationManifestStatus

        init(code: String, name: String, floorValue: Double, payer: String, country: String, status: RollingRevocationManifestStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.payer = payer
            self.country = country
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

        func canMoveTo(_ next: RollingRevocationManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingRevocationManifestStatus.validated || next == RollingRevocationManifestStatus.retired
            case .validated:
                return next == RollingRevocationManifestStatus.published || next == RollingRevocationManifestStatus.retired
            case .published:
                return next == RollingRevocationManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingRevocationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling revocation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling revocation manifest") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> RollingRevocationManifest {
            return RollingRevocationManifest(
                code: code,
                name: name,
                floorValue: floorValue,
                payer: payer,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling revocation manifest in status created.
    static func newRollingRevocationManifest(_ code: String, name: String) -> RollingRevocationManifest {
        return RollingRevocationManifest(
            code: code,
            name: name,
            floorValue: 0.0,
            payer: "",
            country: "",
            status: RollingRevocationManifestStatus.created
        )
    }
}
