import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled modality score is in its life cycle.
    enum ScheduledModalityScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled modality score, with what the planners need to act on it.
    final class ScheduledModalityScore {
        var code: String
        var title: String
        var acuity: Int
        var description: String
        var batchSize: Int
        var margin: Double
        var attempts: Int
        var status: ScheduledModalityScoreStatus

        init(code: String, title: String, acuity: Int, description: String, batchSize: Int, margin: Double, attempts: Int, status: ScheduledModalityScoreStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.description = description
            self.batchSize = batchSize
            self.margin = margin
            self.attempts = attempts
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

        func canMoveTo(_ next: ScheduledModalityScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledModalityScoreStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledModalityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled modality score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedValue() -> Double {
            return ((Double(batchSize) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledModalityScore {
            return ScheduledModalityScore(
                code: code,
                title: title,
                acuity: acuity,
                description: description,
                batchSize: batchSize,
                margin: margin,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled modality score in status requested.
    static func newScheduledModalityScore(_ code: String, title: String) -> ScheduledModalityScore {
        return ScheduledModalityScore(
            code: code,
            title: title,
            acuity: 0,
            description: "",
            batchSize: 0,
            margin: 0.0,
            attempts: 0,
            status: ScheduledModalityScoreStatus.requested
        )
    }
}
