import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual consent form window is in its life cycle.
    enum ManualConsentFormWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a manual consent form window and its current status.
    final class ManualConsentFormWindow {
        var code: String
        var title: String
        var reviewer: String
        var channel: String
        var contactEmail: String
        var specialty: String
        var timezone: String
        var ratio: Double
        var refills: Int
        var procedureCode: String
        var ward: String
        var status: ManualConsentFormWindowStatus

        init(code: String, title: String, reviewer: String, channel: String, contactEmail: String, specialty: String, timezone: String, ratio: Double, refills: Int, procedureCode: String, ward: String, status: ManualConsentFormWindowStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.channel = channel
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.timezone = timezone
            self.ratio = ratio
            self.refills = refills
            self.procedureCode = procedureCode
            self.ward = ward
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

        func canMoveTo(_ next: ManualConsentFormWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualConsentFormWindowStatus.completed || next == ManualConsentFormWindowStatus.cancelled
            case .scheduled:
                return next == ManualConsentFormWindowStatus.inProgress || next == ManualConsentFormWindowStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualConsentFormWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualConsentFormWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual consent form window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return (Double(refills) * ratio * 100).rounded() / 100
        }

        func copyValue() -> ManualConsentFormWindow {
            return ManualConsentFormWindow(
                code: code,
                title: title,
                reviewer: reviewer,
                channel: channel,
                contactEmail: contactEmail,
                specialty: specialty,
                timezone: timezone,
                ratio: ratio,
                refills: refills,
                procedureCode: procedureCode,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual consent form window in status planned.
    static func newManualConsentFormWindow(_ code: String, title: String) -> ManualConsentFormWindow {
        return ManualConsentFormWindow(
            code: code,
            title: title,
            reviewer: "",
            channel: "",
            contactEmail: "",
            specialty: "",
            timezone: "",
            ratio: 0.0,
            refills: 0,
            procedureCode: "",
            ward: "",
            status: ManualConsentFormWindowStatus.planned
        )
    }
}
