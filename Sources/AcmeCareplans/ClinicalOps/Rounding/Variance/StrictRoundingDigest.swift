import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict rounding digest is in its life cycle.
    enum StrictRoundingDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One strict rounding digest, with what the planners need to act on it.
    final class StrictRoundingDigest {
        var code: String
        var title: String
        var score: Double
        var source: String
        var threshold: Double
        var externalRef: String
        var approved: Bool
        var facility: String
        var active: Bool
        var status: StrictRoundingDigestStatus

        init(code: String, title: String, score: Double, source: String, threshold: Double, externalRef: String, approved: Bool, facility: String, active: Bool, status: StrictRoundingDigestStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.source = source
            self.threshold = threshold
            self.externalRef = externalRef
            self.approved = approved
            self.facility = facility
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictRoundingDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == StrictRoundingDigestStatus.inProgress || next == StrictRoundingDigestStatus.cancelled
            case .inProgress:
                return next == StrictRoundingDigestStatus.completed
            case .completed:
                return next == StrictRoundingDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictRoundingDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict rounding digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return ((threshold + score) * 100).rounded() / 100
        }

        func copyValue() -> StrictRoundingDigest {
            return StrictRoundingDigest(
                code: code,
                title: title,
                score: score,
                source: source,
                threshold: threshold,
                externalRef: externalRef,
                approved: approved,
                facility: facility,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict rounding digest in status planned.
    static func newStrictRoundingDigest(_ code: String, title: String) -> StrictRoundingDigest {
        return StrictRoundingDigest(
            code: code,
            title: title,
            score: 0.0,
            source: "",
            threshold: 0.0,
            externalRef: "",
            approved: false,
            facility: "",
            active: false,
            status: StrictRoundingDigestStatus.planned
        )
    }
}
