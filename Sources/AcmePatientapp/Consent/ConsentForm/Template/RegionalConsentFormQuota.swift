import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional consent form quota is in its life cycle.
    enum RegionalConsentFormQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional consent form quota as the consent form team keeps it.
    final class RegionalConsentFormQuota {
        var code: String
        var title: String
        var visible: Bool
        var diagnosisCode: String
        var expiresAt: Int
        var status: RegionalConsentFormQuotaStatus

        init(code: String, title: String, visible: Bool, diagnosisCode: String, expiresAt: Int, status: RegionalConsentFormQuotaStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalConsentFormQuotaStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalConsentFormQuotaStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalConsentFormQuotaStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalConsentFormQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional consent form quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional consent form quota") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> RegionalConsentFormQuota {
            return RegionalConsentFormQuota(
                code: code,
                title: title,
                visible: visible,
                diagnosisCode: diagnosisCode,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional consent form quota in status planned.
    static func newRegionalConsentFormQuota(_ code: String, title: String) -> RegionalConsentFormQuota {
        return RegionalConsentFormQuota(
            code: code,
            title: title,
            visible: false,
            diagnosisCode: "",
            expiresAt: 0,
            status: RegionalConsentFormQuotaStatus.planned
        )
    }
}
