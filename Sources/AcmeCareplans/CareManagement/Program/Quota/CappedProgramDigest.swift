import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped program digest is in its life cycle.
    enum CappedProgramDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped program digest, with what the planners need to act on it.
    final class CappedProgramDigest {
        var code: String
        var label: String
        var segment: String
        var createdAt: Int
        var encounterID: String
        var batchSize: Int
        var status: CappedProgramDigestStatus

        init(code: String, label: String, segment: String, createdAt: Int, encounterID: String, batchSize: Int, status: CappedProgramDigestStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.createdAt = createdAt
            self.encounterID = encounterID
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

        func canMoveTo(_ next: CappedProgramDigestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedProgramDigestStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CappedProgramDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedProgramDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped program digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(batchSize) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedProgramDigest {
            return CappedProgramDigest(
                code: code,
                label: label,
                segment: segment,
                createdAt: createdAt,
                encounterID: encounterID,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped program digest in status open.
    static func newCappedProgramDigest(_ code: String, label: String) -> CappedProgramDigest {
        return CappedProgramDigest(
            code: code,
            label: label,
            segment: "",
            createdAt: 0,
            encounterID: "",
            batchSize: 0,
            status: CappedProgramDigestStatus.`open`
        )
    }
}
