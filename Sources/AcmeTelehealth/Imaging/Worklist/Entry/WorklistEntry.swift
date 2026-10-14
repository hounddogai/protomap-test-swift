import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist entry is in its life cycle.
    enum WorklistEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist entry. Its code is unique within a tenant.
    final class WorklistEntry {
        var code: String
        var name: String
        var refills: Int
        var amount: Double
        var expiresAt: Int
        var reviewer: String
        var ratio: Double
        var status: WorklistEntryStatus

        init(code: String, name: String, refills: Int, amount: Double, expiresAt: Int, reviewer: String, ratio: Double, status: WorklistEntryStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.amount = amount
            self.expiresAt = expiresAt
            self.reviewer = reviewer
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistEntryStatus.approved
            case .approved:
                return next == WorklistEntryStatus.withdrawn
            case .rejected:
                return next == WorklistEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("worklist entry") \(code)"
        }

        func netVolume() -> Double {
            return (amount * ratio * 100).rounded() / 100
        }

        func copyValue() -> WorklistEntry {
            return WorklistEntry(
                code: code,
                name: name,
                refills: refills,
                amount: amount,
                expiresAt: expiresAt,
                reviewer: reviewer,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist entry in status proposed.
    static func newWorklistEntry(_ code: String, name: String) -> WorklistEntry {
        return WorklistEntry(
            code: code,
            name: name,
            refills: 0,
            amount: 0.0,
            expiresAt: 0,
            reviewer: "",
            ratio: 0.0,
            status: WorklistEntryStatus.proposed
        )
    }
}
