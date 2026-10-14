import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness draft is in its life cycle.
    enum WitnessDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A witness draft as the witness team keeps it.
    final class WitnessDraft {
        var code: String
        var label: String
        var ward: String
        var summary: String
        var rate: Double
        var score: Double
        var description: String
        var refills: Int
        var archived: Bool
        var status: WitnessDraftStatus

        init(code: String, label: String, ward: String, summary: String, rate: Double, score: Double, description: String, refills: Int, archived: Bool, status: WitnessDraftStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.summary = summary
            self.rate = rate
            self.score = score
            self.description = description
            self.refills = refills
            self.archived = archived
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

        func canMoveTo(_ next: WitnessDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == WitnessDraftStatus.granted
            case .granted:
                return next == WitnessDraftStatus.revoked || next == WitnessDraftStatus.expired
            case .revoked:
                return next == WitnessDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return (score * rate * 100).rounded() / 100
        }

        func copyValue() -> WitnessDraft {
            return WitnessDraft(
                code: code,
                label: label,
                ward: ward,
                summary: summary,
                rate: rate,
                score: score,
                description: description,
                refills: refills,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a witness draft in status requested.
    static func newWitnessDraft(_ code: String, label: String) -> WitnessDraft {
        return WitnessDraft(
            code: code,
            label: label,
            ward: "",
            summary: "",
            rate: 0.0,
            score: 0.0,
            description: "",
            refills: 0,
            archived: false,
            status: WitnessDraftStatus.requested
        )
    }
}
