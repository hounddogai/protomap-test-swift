import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary discharge plan quota is in its life cycle.
    enum PrimaryDischargePlanQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary discharge plan quota as the discharge plan team keeps it.
    final class PrimaryDischargePlanQuota {
        var code: String
        var name: String
        var threshold: Double
        var retries: Int
        var windowDays: Int
        var status: PrimaryDischargePlanQuotaStatus

        init(code: String, name: String, threshold: Double, retries: Int, windowDays: Int, status: PrimaryDischargePlanQuotaStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.retries = retries
            self.windowDays = windowDays
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

        func canMoveTo(_ next: PrimaryDischargePlanQuotaStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PrimaryDischargePlanQuotaStatus.retired
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

        func moveTo(_ next: PrimaryDischargePlanQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary discharge plan quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(windowDays) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDischargePlanQuota {
            return PrimaryDischargePlanQuota(
                code: code,
                name: name,
                threshold: threshold,
                retries: retries,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary discharge plan quota in status created.
    static func newPrimaryDischargePlanQuota(_ code: String, name: String) -> PrimaryDischargePlanQuota {
        return PrimaryDischargePlanQuota(
            code: code,
            name: name,
            threshold: 0.0,
            retries: 0,
            windowDays: 0,
            status: PrimaryDischargePlanQuotaStatus.created
        )
    }
}
