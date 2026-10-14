import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary worklist notice is in its life cycle.
    enum PrimaryWorklistNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary worklist notice. Its code is unique within a tenant.
    final class PrimaryWorklistNotice {
        var code: String
        var label: String
        var retries: Int
        var rate: Double
        var timezone: String
        var maximum: Double
        var refills: Int
        var payer: String
        var contactEmail: String
        var diagnosisCode: String
        var phone: String
        var status: PrimaryWorklistNoticeStatus

        init(code: String, label: String, retries: Int, rate: Double, timezone: String, maximum: Double, refills: Int, payer: String, contactEmail: String, diagnosisCode: String, phone: String, status: PrimaryWorklistNoticeStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.rate = rate
            self.timezone = timezone
            self.maximum = maximum
            self.refills = refills
            self.payer = payer
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.phone = phone
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

        func canMoveTo(_ next: PrimaryWorklistNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: PrimaryWorklistNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary worklist notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return (rate * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryWorklistNotice {
            return PrimaryWorklistNotice(
                code: code,
                label: label,
                retries: retries,
                rate: rate,
                timezone: timezone,
                maximum: maximum,
                refills: refills,
                payer: payer,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary worklist notice in status created.
    static func newPrimaryWorklistNotice(_ code: String, label: String) -> PrimaryWorklistNotice {
        return PrimaryWorklistNotice(
            code: code,
            label: label,
            retries: 0,
            rate: 0.0,
            timezone: "",
            maximum: 0.0,
            refills: 0,
            payer: "",
            contactEmail: "",
            diagnosisCode: "",
            phone: "",
            status: PrimaryWorklistNoticeStatus.created
        )
    }
}
