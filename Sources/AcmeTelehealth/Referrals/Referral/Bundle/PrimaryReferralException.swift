import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary referral exception is in its life cycle.
    enum PrimaryReferralExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary referral exception, with what the planners need to act on it.
    final class PrimaryReferralException {
        var code: String
        var title: String
        var encounterID: String
        var timezone: String
        var category: String
        var batchSize: Int
        var externalRef: String
        var summary: String
        var status: PrimaryReferralExceptionStatus

        init(code: String, title: String, encounterID: String, timezone: String, category: String, batchSize: Int, externalRef: String, summary: String, status: PrimaryReferralExceptionStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.timezone = timezone
            self.category = category
            self.batchSize = batchSize
            self.externalRef = externalRef
            self.summary = summary
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

        func canMoveTo(_ next: PrimaryReferralExceptionStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryReferralExceptionStatus.retired
            case .validated:
                return next == PrimaryReferralExceptionStatus.published
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

        func moveTo(_ next: PrimaryReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> PrimaryReferralException {
            return PrimaryReferralException(
                code: code,
                title: title,
                encounterID: encounterID,
                timezone: timezone,
                category: category,
                batchSize: batchSize,
                externalRef: externalRef,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary referral exception in status created.
    static func newPrimaryReferralException(_ code: String, title: String) -> PrimaryReferralException {
        return PrimaryReferralException(
            code: code,
            title: title,
            encounterID: "",
            timezone: "",
            category: "",
            batchSize: 0,
            externalRef: "",
            summary: "",
            status: PrimaryReferralExceptionStatus.created
        )
    }
}
