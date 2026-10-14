import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling claim estimate is in its life cycle.
    enum RollingClaimEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling claim estimate. Its code is unique within a tenant.
    final class RollingClaimEstimate {
        var code: String
        var title: String
        var margin: Double
        var clinicianID: String
        var retries: Int
        var maximum: Double
        var checksum: String
        var contactEmail: String
        var copay: Double
        var status: RollingClaimEstimateStatus

        init(code: String, title: String, margin: Double, clinicianID: String, retries: Int, maximum: Double, checksum: String, contactEmail: String, copay: Double, status: RollingClaimEstimateStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.clinicianID = clinicianID
            self.retries = retries
            self.maximum = maximum
            self.checksum = checksum
            self.contactEmail = contactEmail
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingClaimEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingClaimEstimateStatus.approved || next == RollingClaimEstimateStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingClaimEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling claim estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return ((Double(retries) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> RollingClaimEstimate {
            return RollingClaimEstimate(
                code: code,
                title: title,
                margin: margin,
                clinicianID: clinicianID,
                retries: retries,
                maximum: maximum,
                checksum: checksum,
                contactEmail: contactEmail,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling claim estimate in status proposed.
    static func newRollingClaimEstimate(_ code: String, title: String) -> RollingClaimEstimate {
        return RollingClaimEstimate(
            code: code,
            title: title,
            margin: 0.0,
            clinicianID: "",
            retries: 0,
            maximum: 0.0,
            checksum: "",
            contactEmail: "",
            copay: 0.0,
            status: RollingClaimEstimateStatus.proposed
        )
    }
}
