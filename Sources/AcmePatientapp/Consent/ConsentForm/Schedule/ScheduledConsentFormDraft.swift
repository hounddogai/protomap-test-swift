import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled consent form draft is in its life cycle.
    enum ScheduledConsentFormDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled consent form draft. Its code is unique within a tenant.
    final class ScheduledConsentFormDraft {
        var code: String
        var title: String
        var rate: Double
        var checksum: String
        var endsAt: Int
        var status: ScheduledConsentFormDraftStatus

        init(code: String, title: String, rate: Double, checksum: String, endsAt: Int, status: ScheduledConsentFormDraftStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.checksum = checksum
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledConsentFormDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledConsentFormDraftStatus.resolved || next == ScheduledConsentFormDraftStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ScheduledConsentFormDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledConsentFormDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled consent form draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((rate - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledConsentFormDraft {
            return ScheduledConsentFormDraft(
                code: code,
                title: title,
                rate: rate,
                checksum: checksum,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled consent form draft in status open.
    static func newScheduledConsentFormDraft(_ code: String, title: String) -> ScheduledConsentFormDraft {
        return ScheduledConsentFormDraft(
            code: code,
            title: title,
            rate: 0.0,
            checksum: "",
            endsAt: 0,
            status: ScheduledConsentFormDraftStatus.`open`
        )
    }
}
