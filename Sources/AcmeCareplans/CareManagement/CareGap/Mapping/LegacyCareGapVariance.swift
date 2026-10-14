import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy care gap variance is in its life cycle.
    enum LegacyCareGapVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy care gap variance. Its code is unique within a tenant.
    final class LegacyCareGapVariance {
        var code: String
        var name: String
        var acuity: Int
        var checksum: String
        var region: String
        var status: LegacyCareGapVarianceStatus

        init(code: String, name: String, acuity: Int, checksum: String, region: String, status: LegacyCareGapVarianceStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.checksum = checksum
            self.region = region
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

        func canMoveTo(_ next: LegacyCareGapVarianceStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyCareGapVarianceStatus.revoked || next == LegacyCareGapVarianceStatus.expired
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

        func moveTo(_ next: LegacyCareGapVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care gap variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> LegacyCareGapVariance {
            return LegacyCareGapVariance(
                code: code,
                name: name,
                acuity: acuity,
                checksum: checksum,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy care gap variance in status requested.
    static func newLegacyCareGapVariance(_ code: String, name: String) -> LegacyCareGapVariance {
        return LegacyCareGapVariance(
            code: code,
            name: name,
            acuity: 0,
            checksum: "",
            region: "",
            status: LegacyCareGapVarianceStatus.requested
        )
    }
}
