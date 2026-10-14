import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal study batch is in its life cycle.
    enum SeasonalStudyBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One seasonal study batch, with what the planners need to act on it.
    final class SeasonalStudyBatch {
        var code: String
        var name: String
        var payer: String
        var facility: String
        var title: String
        var score: Double
        var status: SeasonalStudyBatchStatus

        init(code: String, name: String, payer: String, facility: String, title: String, score: Double, status: SeasonalStudyBatchStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.facility = facility
            self.title = title
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalStudyBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalStudyBatchStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SeasonalStudyBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalStudyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal study batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal study batch") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SeasonalStudyBatch {
            return SeasonalStudyBatch(
                code: code,
                name: name,
                payer: payer,
                facility: facility,
                title: title,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal study batch in status proposed.
    static func newSeasonalStudyBatch(_ code: String, name: String) -> SeasonalStudyBatch {
        return SeasonalStudyBatch(
            code: code,
            name: name,
            payer: "",
            facility: "",
            title: "",
            score: 0.0,
            status: SeasonalStudyBatchStatus.proposed
        )
    }
}
