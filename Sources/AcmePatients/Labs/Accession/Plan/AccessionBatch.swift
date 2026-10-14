import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession batch is in its life cycle.
    enum AccessionBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One accession batch, with what the planners need to act on it.
    final class AccessionBatch {
        var code: String
        var title: String
        var description: String
        var floorValue: Double
        var summary: String
        var encounterID: String
        var expiresAt: Int
        var status: AccessionBatchStatus

        init(code: String, title: String, description: String, floorValue: Double, summary: String, encounterID: String, expiresAt: Int, status: AccessionBatchStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.floorValue = floorValue
            self.summary = summary
            self.encounterID = encounterID
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: AccessionBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == AccessionBatchStatus.inProgress
            case .scheduled:
                return next == AccessionBatchStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AccessionBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedExposure() -> Double {
            return ((Double(expiresAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AccessionBatch {
            return AccessionBatch(
                code: code,
                title: title,
                description: description,
                floorValue: floorValue,
                summary: summary,
                encounterID: encounterID,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession batch in status planned.
    static func newAccessionBatch(_ code: String, title: String) -> AccessionBatch {
        return AccessionBatch(
            code: code,
            title: title,
            description: "",
            floorValue: 0.0,
            summary: "",
            encounterID: "",
            expiresAt: 0,
            status: AccessionBatchStatus.planned
        )
    }
}
