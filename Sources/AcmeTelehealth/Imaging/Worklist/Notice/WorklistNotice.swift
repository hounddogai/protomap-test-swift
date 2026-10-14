import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist notice is in its life cycle.
    enum WorklistNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A worklist notice as the worklist team keeps it.
    final class WorklistNotice {
        var code: String
        var name: String
        var amount: Double
        var retries: Int
        var archived: Bool
        var segment: String
        var source: String
        var batchSize: Int
        var acuity: Int
        var approved: Bool
        var pinned: Bool
        var status: WorklistNoticeStatus

        init(code: String, name: String, amount: Double, retries: Int, archived: Bool, segment: String, source: String, batchSize: Int, acuity: Int, approved: Bool, pinned: Bool, status: WorklistNoticeStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.retries = retries
            self.archived = archived
            self.segment = segment
            self.source = source
            self.batchSize = batchSize
            self.acuity = acuity
            self.approved = approved
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistNoticeStatus) -> Bool {
            switch status {
            case .new:
                return next == WorklistNoticeStatus.queued || next == WorklistNoticeStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WorklistNoticeStatus.done
            case .done:
                return next == WorklistNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return (Double(retries) * amount * 100).rounded() / 100
        }

        func copyValue() -> WorklistNotice {
            return WorklistNotice(
                code: code,
                name: name,
                amount: amount,
                retries: retries,
                archived: archived,
                segment: segment,
                source: source,
                batchSize: batchSize,
                acuity: acuity,
                approved: approved,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a worklist notice in status new.
    static func newWorklistNotice(_ code: String, name: String) -> WorklistNotice {
        return WorklistNotice(
            code: code,
            name: name,
            amount: 0.0,
            retries: 0,
            archived: false,
            segment: "",
            source: "",
            batchSize: 0,
            acuity: 0,
            approved: false,
            pinned: false,
            status: WorklistNoticeStatus.new
        )
    }
}
