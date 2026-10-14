import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy care protocol digest is in its life cycle.
    enum LegacyCareProtocolDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One legacy care protocol digest, with what the planners need to act on it.
    final class LegacyCareProtocolDigest {
        var code: String
        var title: String
        var checksum: String
        var locale: String
        var clinicianID: String
        var score: Double
        var status: LegacyCareProtocolDigestStatus

        init(code: String, title: String, checksum: String, locale: String, clinicianID: String, score: Double, status: LegacyCareProtocolDigestStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.locale = locale
            self.clinicianID = clinicianID
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCareProtocolDigestStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyCareProtocolDigestStatus.pending || next == LegacyCareProtocolDigestStatus.closed
            case .pending:
                return next == LegacyCareProtocolDigestStatus.closed
            case .active:
                return next == LegacyCareProtocolDigestStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyCareProtocolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care protocol digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LegacyCareProtocolDigest {
            return LegacyCareProtocolDigest(
                code: code,
                title: title,
                checksum: checksum,
                locale: locale,
                clinicianID: clinicianID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy care protocol digest in status draft.
    static func newLegacyCareProtocolDigest(_ code: String, title: String) -> LegacyCareProtocolDigest {
        return LegacyCareProtocolDigest(
            code: code,
            title: title,
            checksum: "",
            locale: "",
            clinicianID: "",
            score: 0.0,
            status: LegacyCareProtocolDigestStatus.draft
        )
    }
}
