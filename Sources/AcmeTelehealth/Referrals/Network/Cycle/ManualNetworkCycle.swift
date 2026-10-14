import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network cycle is in its life cycle.
    enum ManualNetworkCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual network cycle. Its code is unique within a tenant.
    final class ManualNetworkCycle {
        var code: String
        var name: String
        var revision: Int
        var dosageMg: Double
        var currency: String
        var summary: String
        var checksum: String
        var ward: String
        var locale: String
        var status: ManualNetworkCycleStatus

        init(code: String, name: String, revision: Int, dosageMg: Double, currency: String, summary: String, checksum: String, ward: String, locale: String, status: ManualNetworkCycleStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.dosageMg = dosageMg
            self.currency = currency
            self.summary = summary
            self.checksum = checksum
            self.ward = ward
            self.locale = locale
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

        func canMoveTo(_ next: ManualNetworkCycleStatus) -> Bool {
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
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualNetworkCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualNetworkCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((Double(revision) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkCycle {
            return ManualNetworkCycle(
                code: code,
                name: name,
                revision: revision,
                dosageMg: dosageMg,
                currency: currency,
                summary: summary,
                checksum: checksum,
                ward: ward,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual network cycle in status requested.
    static func newManualNetworkCycle(_ code: String, name: String) -> ManualNetworkCycle {
        return ManualNetworkCycle(
            code: code,
            name: name,
            revision: 0,
            dosageMg: 0.0,
            currency: "",
            summary: "",
            checksum: "",
            ward: "",
            locale: "",
            status: ManualNetworkCycleStatus.requested
        )
    }
}
