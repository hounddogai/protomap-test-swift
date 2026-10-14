import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional slot batch is in its life cycle.
    enum RegionalSlotBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One regional slot batch, with what the planners need to act on it.
    final class RegionalSlotBatch {
        var code: String
        var title: String
        var category: String
        var priority: Int
        var specialty: String
        var acuity: Int
        var pinned: Bool
        var status: RegionalSlotBatchStatus

        init(code: String, title: String, category: String, priority: Int, specialty: String, acuity: Int, pinned: Bool, status: RegionalSlotBatchStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.priority = priority
            self.specialty = specialty
            self.acuity = acuity
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalSlotBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalSlotBatchStatus.published
            case .validated:
                return next == RegionalSlotBatchStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalSlotBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional slot batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return (Double(acuity) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSlotBatch {
            return RegionalSlotBatch(
                code: code,
                title: title,
                category: category,
                priority: priority,
                specialty: specialty,
                acuity: acuity,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional slot batch in status created.
    static func newRegionalSlotBatch(_ code: String, title: String) -> RegionalSlotBatch {
        return RegionalSlotBatch(
            code: code,
            title: title,
            category: "",
            priority: 0,
            specialty: "",
            acuity: 0,
            pinned: false,
            status: RegionalSlotBatchStatus.created
        )
    }
}
