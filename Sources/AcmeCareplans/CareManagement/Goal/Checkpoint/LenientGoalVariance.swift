import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient goal variance is in its life cycle.
    enum LenientGoalVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient goal variance. Its code is unique within a tenant.
    final class LenientGoalVariance {
        var code: String
        var name: String
        var channel: String
        var dosageMg: Double
        var floorValue: Double
        var ratio: Double
        var label: String
        var revision: Int
        var score: Double
        var archived: Bool
        var batchSize: Int
        var status: LenientGoalVarianceStatus

        init(code: String, name: String, channel: String, dosageMg: Double, floorValue: Double, ratio: Double, label: String, revision: Int, score: Double, archived: Bool, batchSize: Int, status: LenientGoalVarianceStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.ratio = ratio
            self.label = label
            self.revision = revision
            self.score = score
            self.archived = archived
            self.batchSize = batchSize
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

        func canMoveTo(_ next: LenientGoalVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientGoalVarianceStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LenientGoalVarianceStatus.reopened
            case .reopened:
                return next == LenientGoalVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientGoalVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient goal variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((ratio - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> LenientGoalVariance {
            return LenientGoalVariance(
                code: code,
                name: name,
                channel: channel,
                dosageMg: dosageMg,
                floorValue: floorValue,
                ratio: ratio,
                label: label,
                revision: revision,
                score: score,
                archived: archived,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient goal variance in status open.
    static func newLenientGoalVariance(_ code: String, name: String) -> LenientGoalVariance {
        return LenientGoalVariance(
            code: code,
            name: name,
            channel: "",
            dosageMg: 0.0,
            floorValue: 0.0,
            ratio: 0.0,
            label: "",
            revision: 0,
            score: 0.0,
            archived: false,
            batchSize: 0,
            status: LenientGoalVarianceStatus.`open`
        )
    }
}
