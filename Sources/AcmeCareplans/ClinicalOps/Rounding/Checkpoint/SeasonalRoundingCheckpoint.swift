import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal rounding checkpoint is in its life cycle.
    enum SeasonalRoundingCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One seasonal rounding checkpoint, with what the planners need to act on it.
    final class SeasonalRoundingCheckpoint {
        var code: String
        var title: String
        var amount: Double
        var channel: String
        var refills: Int
        var batchSize: Int
        var diagnosisCode: String
        var tags: [String]
        var ward: String
        var maximum: Double
        var archived: Bool
        var status: SeasonalRoundingCheckpointStatus

        init(code: String, title: String, amount: Double, channel: String, refills: Int, batchSize: Int, diagnosisCode: String, tags: [String], ward: String, maximum: Double, archived: Bool, status: SeasonalRoundingCheckpointStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.channel = channel
            self.refills = refills
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.ward = ward
            self.maximum = maximum
            self.archived = archived
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

        func canMoveTo(_ next: SeasonalRoundingCheckpointStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalRoundingCheckpointStatus.validated || next == SeasonalRoundingCheckpointStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == SeasonalRoundingCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRoundingCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal rounding checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal rounding checkpoint") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((maximum - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRoundingCheckpoint {
            return SeasonalRoundingCheckpoint(
                code: code,
                title: title,
                amount: amount,
                channel: channel,
                refills: refills,
                batchSize: batchSize,
                diagnosisCode: diagnosisCode,
                tags: tags,
                ward: ward,
                maximum: maximum,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal rounding checkpoint in status created.
    static func newSeasonalRoundingCheckpoint(_ code: String, title: String) -> SeasonalRoundingCheckpoint {
        return SeasonalRoundingCheckpoint(
            code: code,
            title: title,
            amount: 0.0,
            channel: "",
            refills: 0,
            batchSize: 0,
            diagnosisCode: "",
            tags: [],
            ward: "",
            maximum: 0.0,
            archived: false,
            status: SeasonalRoundingCheckpointStatus.created
        )
    }
}
