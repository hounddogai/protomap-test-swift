import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall digest is in its life cycle.
    enum RecallDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One recall digest, with what the planners need to act on it.
    final class RecallDigest {
        var code: String
        var title: String
        var payer: String
        var createdAt: Int
        var visible: Bool
        var maximum: Double
        var minimum: Double
        var status: RecallDigestStatus

        init(code: String, title: String, payer: String, createdAt: Int, visible: Bool, maximum: Double, minimum: Double, status: RecallDigestStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.createdAt = createdAt
            self.visible = visible
            self.maximum = maximum
            self.minimum = minimum
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

        func canMoveTo(_ next: RecallDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == RecallDigestStatus.inProgress || next == RecallDigestStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RecallDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("recall digest") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(createdAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> RecallDigest {
            return RecallDigest(
                code: code,
                title: title,
                payer: payer,
                createdAt: createdAt,
                visible: visible,
                maximum: maximum,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall digest in status planned.
    static func newRecallDigest(_ code: String, title: String) -> RecallDigest {
        return RecallDigest(
            code: code,
            title: title,
            payer: "",
            createdAt: 0,
            visible: false,
            maximum: 0.0,
            minimum: 0.0,
            status: RecallDigestStatus.planned
        )
    }
}
