import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending care gap draft is in its life cycle.
    enum PendingCareGapDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending care gap draft, with what the planners need to act on it.
    final class PendingCareGapDraft {
        var code: String
        var name: String
        var weight: Double
        var capacity: Int
        var batchSize: Int
        var payer: String
        var contactEmail: String
        var status: PendingCareGapDraftStatus

        init(code: String, name: String, weight: Double, capacity: Int, batchSize: Int, payer: String, contactEmail: String, status: PendingCareGapDraftStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.capacity = capacity
            self.batchSize = batchSize
            self.payer = payer
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: PendingCareGapDraftStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingCareGapDraftStatus.inProgress
            case .scheduled:
                return next == PendingCareGapDraftStatus.inProgress || next == PendingCareGapDraftStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingCareGapDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care gap draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCareGapDraft {
            return PendingCareGapDraft(
                code: code,
                name: name,
                weight: weight,
                capacity: capacity,
                batchSize: batchSize,
                payer: payer,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending care gap draft in status planned.
    static func newPendingCareGapDraft(_ code: String, name: String) -> PendingCareGapDraft {
        return PendingCareGapDraft(
            code: code,
            name: name,
            weight: 0.0,
            capacity: 0,
            batchSize: 0,
            payer: "",
            contactEmail: "",
            status: PendingCareGapDraftStatus.planned
        )
    }
}
