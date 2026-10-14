import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional denial policy is in its life cycle.
    enum RegionalDenialPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional denial policy. Its code is unique within a tenant.
    final class RegionalDenialPolicy {
        var code: String
        var title: String
        var revision: Int
        var diagnosisCode: String
        var budget: Double
        var dosageMg: Double
        var endsAt: Int
        var region: String
        var currency: String
        var checksum: String
        var status: RegionalDenialPolicyStatus

        init(code: String, title: String, revision: Int, diagnosisCode: String, budget: Double, dosageMg: Double, endsAt: Int, region: String, currency: String, checksum: String, status: RegionalDenialPolicyStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.region = region
            self.currency = currency
            self.checksum = checksum
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

        func canMoveTo(_ next: RegionalDenialPolicyStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RegionalDenialPolicyStatus.revoked || next == RegionalDenialPolicyStatus.expired
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

        func moveTo(_ next: RegionalDenialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional denial policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((dosageMg - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDenialPolicy {
            return RegionalDenialPolicy(
                code: code,
                title: title,
                revision: revision,
                diagnosisCode: diagnosisCode,
                budget: budget,
                dosageMg: dosageMg,
                endsAt: endsAt,
                region: region,
                currency: currency,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional denial policy in status requested.
    static func newRegionalDenialPolicy(_ code: String, title: String) -> RegionalDenialPolicy {
        return RegionalDenialPolicy(
            code: code,
            title: title,
            revision: 0,
            diagnosisCode: "",
            budget: 0.0,
            dosageMg: 0.0,
            endsAt: 0,
            region: "",
            currency: "",
            checksum: "",
            status: RegionalDenialPolicyStatus.requested
        )
    }
}
