import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy authorization segment is in its life cycle.
    enum LegacyAuthorizationSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One legacy authorization segment, with what the planners need to act on it.
    final class LegacyAuthorizationSegment {
        var code: String
        var title: String
        var diagnosisCode: String
        var archived: Bool
        var startsAt: Int
        var sequence: Int
        var refills: Int
        var quantity: Int
        var summary: String
        var score: Double
        var timezone: String
        var status: LegacyAuthorizationSegmentStatus

        init(code: String, title: String, diagnosisCode: String, archived: Bool, startsAt: Int, sequence: Int, refills: Int, quantity: Int, summary: String, score: Double, timezone: String, status: LegacyAuthorizationSegmentStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.startsAt = startsAt
            self.sequence = sequence
            self.refills = refills
            self.quantity = quantity
            self.summary = summary
            self.score = score
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyAuthorizationSegmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyAuthorizationSegmentStatus.granted || next == LegacyAuthorizationSegmentStatus.revoked
            case .granted:
                return next == LegacyAuthorizationSegmentStatus.revoked || next == LegacyAuthorizationSegmentStatus.expired
            case .revoked:
                return next == LegacyAuthorizationSegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAuthorizationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy authorization segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return (Double(startsAt) * score * 100).rounded() / 100
        }

        func copyValue() -> LegacyAuthorizationSegment {
            return LegacyAuthorizationSegment(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                archived: archived,
                startsAt: startsAt,
                sequence: sequence,
                refills: refills,
                quantity: quantity,
                summary: summary,
                score: score,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy authorization segment in status requested.
    static func newLegacyAuthorizationSegment(_ code: String, title: String) -> LegacyAuthorizationSegment {
        return LegacyAuthorizationSegment(
            code: code,
            title: title,
            diagnosisCode: "",
            archived: false,
            startsAt: 0,
            sequence: 0,
            refills: 0,
            quantity: 0,
            summary: "",
            score: 0.0,
            timezone: "",
            status: LegacyAuthorizationSegmentStatus.requested
        )
    }
}
