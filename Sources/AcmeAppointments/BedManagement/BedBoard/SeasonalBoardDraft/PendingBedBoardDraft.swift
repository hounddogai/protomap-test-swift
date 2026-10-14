import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending bed board draft is in its life cycle.
    enum PendingBedBoardDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending bed board draft, with what the planners need to act on it.
    final class PendingBedBoardDraft {
        var code: String
        var name: String
        var segment: String
        var capacity: Int
        var amount: Double
        var ward: String
        var cost: Double
        var endsAt: Int
        var startsAt: Int
        var batchSize: Int
        var procedureCode: String
        var status: PendingBedBoardDraftStatus

        init(code: String, name: String, segment: String, capacity: Int, amount: Double, ward: String, cost: Double, endsAt: Int, startsAt: Int, batchSize: Int, procedureCode: String, status: PendingBedBoardDraftStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.capacity = capacity
            self.amount = amount
            self.ward = ward
            self.cost = cost
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: PendingBedBoardDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingBedBoardDraftStatus.done
            case .queued:
                return next == PendingBedBoardDraftStatus.running || next == PendingBedBoardDraftStatus.failed
            case .running:
                return next == PendingBedBoardDraftStatus.done
            case .done:
                return next == PendingBedBoardDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingBedBoardDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending bed board draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return ((Double(capacity) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingBedBoardDraft {
            return PendingBedBoardDraft(
                code: code,
                name: name,
                segment: segment,
                capacity: capacity,
                amount: amount,
                ward: ward,
                cost: cost,
                endsAt: endsAt,
                startsAt: startsAt,
                batchSize: batchSize,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending bed board draft in status new.
    static func newPendingBedBoardDraft(_ code: String, name: String) -> PendingBedBoardDraft {
        return PendingBedBoardDraft(
            code: code,
            name: name,
            segment: "",
            capacity: 0,
            amount: 0.0,
            ward: "",
            cost: 0.0,
            endsAt: 0,
            startsAt: 0,
            batchSize: 0,
            procedureCode: "",
            status: PendingBedBoardDraftStatus.new
        )
    }
}
