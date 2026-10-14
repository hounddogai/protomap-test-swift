import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched accession notice is in its life cycle.
    enum BatchedAccessionNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched accession notice, with what the planners need to act on it.
    final class BatchedAccessionNotice {
        var code: String
        var name: String
        var ceiling: Double
        var allergy: String
        var notes: String
        var procedureCode: String
        var summary: String
        var checksum: String
        var refills: Int
        var status: BatchedAccessionNoticeStatus

        init(code: String, name: String, ceiling: Double, allergy: String, notes: String, procedureCode: String, summary: String, checksum: String, refills: Int, status: BatchedAccessionNoticeStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.allergy = allergy
            self.notes = notes
            self.procedureCode = procedureCode
            self.summary = summary
            self.checksum = checksum
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedAccessionNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedAccessionNoticeStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BatchedAccessionNoticeStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedAccessionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched accession notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched accession notice") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAccessionNotice {
            return BatchedAccessionNotice(
                code: code,
                name: name,
                ceiling: ceiling,
                allergy: allergy,
                notes: notes,
                procedureCode: procedureCode,
                summary: summary,
                checksum: checksum,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched accession notice in status idle.
    static func newBatchedAccessionNotice(_ code: String, name: String) -> BatchedAccessionNotice {
        return BatchedAccessionNotice(
            code: code,
            name: name,
            ceiling: 0.0,
            allergy: "",
            notes: "",
            procedureCode: "",
            summary: "",
            checksum: "",
            refills: 0,
            status: BatchedAccessionNoticeStatus.idle
        )
    }
}
