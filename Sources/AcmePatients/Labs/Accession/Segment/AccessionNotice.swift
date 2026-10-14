import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession notice is in its life cycle.
    enum AccessionNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a accession notice and its current status.
    final class AccessionNotice {
        var code: String
        var label: String
        var timezone: String
        var refills: Int
        var revision: Int
        var updatedAt: Int
        var externalRef: String
        var startsAt: Int
        var windowDays: Int
        var attempts: Int
        var payer: String
        var status: AccessionNoticeStatus

        init(code: String, label: String, timezone: String, refills: Int, revision: Int, updatedAt: Int, externalRef: String, startsAt: Int, windowDays: Int, attempts: Int, payer: String, status: AccessionNoticeStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.refills = refills
            self.revision = revision
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.attempts = attempts
            self.payer = payer
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

        func canMoveTo(_ next: AccessionNoticeStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AccessionNoticeStatus.inProgress || next == AccessionNoticeStatus.cancelled
            case .inProgress:
                return next == AccessionNoticeStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AccessionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netTotal() -> Double {
            return (Double(updatedAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> AccessionNotice {
            return AccessionNotice(
                code: code,
                label: label,
                timezone: timezone,
                refills: refills,
                revision: revision,
                updatedAt: updatedAt,
                externalRef: externalRef,
                startsAt: startsAt,
                windowDays: windowDays,
                attempts: attempts,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession notice in status planned.
    static func newAccessionNotice(_ code: String, label: String) -> AccessionNotice {
        return AccessionNotice(
            code: code,
            label: label,
            timezone: "",
            refills: 0,
            revision: 0,
            updatedAt: 0,
            externalRef: "",
            startsAt: 0,
            windowDays: 0,
            attempts: 0,
            payer: "",
            status: AccessionNoticeStatus.planned
        )
    }
}
