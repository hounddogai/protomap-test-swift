import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped referral rollup is in its life cycle.
    enum CappedReferralRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped referral rollup. Its code is unique within a tenant.
    final class CappedReferralRollup {
        var code: String
        var title: String
        var description: String
        var batchSize: Int
        var locale: String
        var diagnosisCode: String
        var phone: String
        var tags: [String]
        var status: CappedReferralRollupStatus

        init(code: String, title: String, description: String, batchSize: Int, locale: String, diagnosisCode: String, phone: String, tags: [String], status: CappedReferralRollupStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.batchSize = batchSize
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.tags = tags
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

        func canMoveTo(_ next: CappedReferralRollupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedReferralRollupStatus.published || next == CappedReferralRollupStatus.retired
            case .published:
                return next == CappedReferralRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedReferralRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped referral rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> CappedReferralRollup {
            return CappedReferralRollup(
                code: code,
                title: title,
                description: description,
                batchSize: batchSize,
                locale: locale,
                diagnosisCode: diagnosisCode,
                phone: phone,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped referral rollup in status created.
    static func newCappedReferralRollup(_ code: String, title: String) -> CappedReferralRollup {
        return CappedReferralRollup(
            code: code,
            title: title,
            description: "",
            batchSize: 0,
            locale: "",
            diagnosisCode: "",
            phone: "",
            tags: [],
            status: CappedReferralRollupStatus.created
        )
    }
}
