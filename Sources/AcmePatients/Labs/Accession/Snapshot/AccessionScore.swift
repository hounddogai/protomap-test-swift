import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession score is in its life cycle.
    enum AccessionScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One accession score, with what the planners need to act on it.
    final class AccessionScore {
        var code: String
        var title: String
        var archived: Bool
        var ceiling: Double
        var bed: String
        var refills: Int
        var region: String
        var status: AccessionScoreStatus

        init(code: String, title: String, archived: Bool, ceiling: Double, bed: String, refills: Int, region: String, status: AccessionScoreStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.ceiling = ceiling
            self.bed = bed
            self.refills = refills
            self.region = region
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

        func canMoveTo(_ next: AccessionScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == AccessionScoreStatus.validated
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AccessionScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return (ceiling * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> AccessionScore {
            return AccessionScore(
                code: code,
                title: title,
                archived: archived,
                ceiling: ceiling,
                bed: bed,
                refills: refills,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a accession score in status created.
    static func newAccessionScore(_ code: String, title: String) -> AccessionScore {
        return AccessionScore(
            code: code,
            title: title,
            archived: false,
            ceiling: 0.0,
            bed: "",
            refills: 0,
            region: "",
            status: AccessionScoreStatus.created
        )
    }
}
