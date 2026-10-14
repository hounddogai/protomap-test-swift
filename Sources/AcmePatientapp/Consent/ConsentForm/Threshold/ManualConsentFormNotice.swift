import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual consent form notice is in its life cycle.
    enum ManualConsentFormNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual consent form notice. Its code is unique within a tenant.
    final class ManualConsentFormNotice {
        var code: String
        var label: String
        var attempts: Int
        var region: String
        var startsAt: Int
        var ward: String
        var status: ManualConsentFormNoticeStatus

        init(code: String, label: String, attempts: Int, region: String, startsAt: Int, ward: String, status: ManualConsentFormNoticeStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.region = region
            self.startsAt = startsAt
            self.ward = ward
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

        func canMoveTo(_ next: ManualConsentFormNoticeStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualConsentFormNoticeStatus.validated || next == ManualConsentFormNoticeStatus.retired
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualConsentFormNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual consent form notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ManualConsentFormNotice {
            return ManualConsentFormNotice(
                code: code,
                label: label,
                attempts: attempts,
                region: region,
                startsAt: startsAt,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual consent form notice in status created.
    static func newManualConsentFormNotice(_ code: String, label: String) -> ManualConsentFormNotice {
        return ManualConsentFormNotice(
            code: code,
            label: label,
            attempts: 0,
            region: "",
            startsAt: 0,
            ward: "",
            status: ManualConsentFormNoticeStatus.created
        )
    }
}
