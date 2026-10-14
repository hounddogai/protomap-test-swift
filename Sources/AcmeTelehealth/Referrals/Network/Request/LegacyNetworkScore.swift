import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy network score is in its life cycle.
    enum LegacyNetworkScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy network score and its current status.
    final class LegacyNetworkScore {
        var code: String
        var title: String
        var ownerID: String
        var createdAt: Int
        var weight: Double
        var discount: Double
        var bed: String
        var revision: Int
        var summary: String
        var durationMinutes: Int
        var status: LegacyNetworkScoreStatus

        init(code: String, title: String, ownerID: String, createdAt: Int, weight: Double, discount: Double, bed: String, revision: Int, summary: String, durationMinutes: Int, status: LegacyNetworkScoreStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.createdAt = createdAt
            self.weight = weight
            self.discount = discount
            self.bed = bed
            self.revision = revision
            self.summary = summary
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: LegacyNetworkScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LegacyNetworkScoreStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyNetworkScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyNetworkScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy network score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((weight + discount) * 100).rounded() / 100
        }

        func copyValue() -> LegacyNetworkScore {
            return LegacyNetworkScore(
                code: code,
                title: title,
                ownerID: ownerID,
                createdAt: createdAt,
                weight: weight,
                discount: discount,
                bed: bed,
                revision: revision,
                summary: summary,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy network score in status open.
    static func newLegacyNetworkScore(_ code: String, title: String) -> LegacyNetworkScore {
        return LegacyNetworkScore(
            code: code,
            title: title,
            ownerID: "",
            createdAt: 0,
            weight: 0.0,
            discount: 0.0,
            bed: "",
            revision: 0,
            summary: "",
            durationMinutes: 0,
            status: LegacyNetworkScoreStatus.`open`
        )
    }
}
