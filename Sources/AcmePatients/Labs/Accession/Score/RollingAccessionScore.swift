import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession score is in its life cycle.
    enum RollingAccessionScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling accession score as the accession team keeps it.
    final class RollingAccessionScore {
        var code: String
        var name: String
        var description: String
        var ratio: Double
        var checksum: String
        var status: RollingAccessionScoreStatus

        init(code: String, name: String, description: String, ratio: Double, checksum: String, status: RollingAccessionScoreStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.ratio = ratio
            self.checksum = checksum
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

        func canMoveTo(_ next: RollingAccessionScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingAccessionScoreStatus.inReview || next == RollingAccessionScoreStatus.resolved
            case .inReview:
                return next == RollingAccessionScoreStatus.resolved || next == RollingAccessionScoreStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RollingAccessionScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAccessionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> RollingAccessionScore {
            return RollingAccessionScore(
                code: code,
                name: name,
                description: description,
                ratio: ratio,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling accession score in status open.
    static func newRollingAccessionScore(_ code: String, name: String) -> RollingAccessionScore {
        return RollingAccessionScore(
            code: code,
            name: name,
            description: "",
            ratio: 0.0,
            checksum: "",
            status: RollingAccessionScoreStatus.`open`
        )
    }
}
