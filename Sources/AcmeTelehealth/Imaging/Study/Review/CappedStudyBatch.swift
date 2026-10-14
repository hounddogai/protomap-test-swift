import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped study batch is in its life cycle.
    enum CappedStudyBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped study batch and its current status.
    final class CappedStudyBatch {
        var code: String
        var name: String
        var windowDays: Int
        var version: Int
        var payer: String
        var retries: Int
        var revision: Int
        var createdAt: Int
        var status: CappedStudyBatchStatus

        init(code: String, name: String, windowDays: Int, version: Int, payer: String, retries: Int, revision: Int, createdAt: Int, status: CappedStudyBatchStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.version = version
            self.payer = payer
            self.retries = retries
            self.revision = revision
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CappedStudyBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedStudyBatchStatus.resolved || next == CappedStudyBatchStatus.archived
            case .inReview:
                return next == CappedStudyBatchStatus.resolved || next == CappedStudyBatchStatus.archived
            case .resolved:
                return next == CappedStudyBatchStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CappedStudyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped study batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return (Double(version) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> CappedStudyBatch {
            return CappedStudyBatch(
                code: code,
                name: name,
                windowDays: windowDays,
                version: version,
                payer: payer,
                retries: retries,
                revision: revision,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped study batch in status open.
    static func newCappedStudyBatch(_ code: String, name: String) -> CappedStudyBatch {
        return CappedStudyBatch(
            code: code,
            name: name,
            windowDays: 0,
            version: 0,
            payer: "",
            retries: 0,
            revision: 0,
            createdAt: 0,
            status: CappedStudyBatchStatus.`open`
        )
    }
}
