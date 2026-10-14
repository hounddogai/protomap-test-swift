import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict handoff draft is in its life cycle.
    enum StrictHandoffDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict handoff draft as the handoff team keeps it.
    final class StrictHandoffDraft {
        var code: String
        var label: String
        var clinicianID: String
        var version: Int
        var startsAt: Int
        var channel: String
        var maximum: Double
        var ownerID: String
        var title: String
        var graceDays: Int
        var score: Double
        var status: StrictHandoffDraftStatus

        init(code: String, label: String, clinicianID: String, version: Int, startsAt: Int, channel: String, maximum: Double, ownerID: String, title: String, graceDays: Int, score: Double, status: StrictHandoffDraftStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.version = version
            self.startsAt = startsAt
            self.channel = channel
            self.maximum = maximum
            self.ownerID = ownerID
            self.title = title
            self.graceDays = graceDays
            self.score = score
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

        func canMoveTo(_ next: StrictHandoffDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictHandoffDraftStatus.revoked || next == StrictHandoffDraftStatus.expired
            case .granted:
                return next == StrictHandoffDraftStatus.revoked || next == StrictHandoffDraftStatus.expired
            case .revoked:
                return next == StrictHandoffDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictHandoffDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict handoff draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return ((Double(graceDays) + score) * 100).rounded() / 100
        }

        func copyValue() -> StrictHandoffDraft {
            return StrictHandoffDraft(
                code: code,
                label: label,
                clinicianID: clinicianID,
                version: version,
                startsAt: startsAt,
                channel: channel,
                maximum: maximum,
                ownerID: ownerID,
                title: title,
                graceDays: graceDays,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict handoff draft in status requested.
    static func newStrictHandoffDraft(_ code: String, label: String) -> StrictHandoffDraft {
        return StrictHandoffDraft(
            code: code,
            label: label,
            clinicianID: "",
            version: 0,
            startsAt: 0,
            channel: "",
            maximum: 0.0,
            ownerID: "",
            title: "",
            graceDays: 0,
            score: 0.0,
            status: StrictHandoffDraftStatus.requested
        )
    }
}
