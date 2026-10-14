import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped inventory request is in its life cycle.
    enum CappedInventoryRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped inventory request, with what the planners need to act on it.
    final class CappedInventoryRequest {
        var code: String
        var label: String
        var capacity: Int
        var procedureCode: String
        var tags: [String]
        var approved: Bool
        var bed: String
        var attempts: Int
        var currency: String
        var status: CappedInventoryRequestStatus

        init(code: String, label: String, capacity: Int, procedureCode: String, tags: [String], approved: Bool, bed: String, attempts: Int, currency: String, status: CappedInventoryRequestStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.procedureCode = procedureCode
            self.tags = tags
            self.approved = approved
            self.bed = bed
            self.attempts = attempts
            self.currency = currency
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

        func canMoveTo(_ next: CappedInventoryRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedInventoryRequestStatus.inProgress || next == CappedInventoryRequestStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: CappedInventoryRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped inventory request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped inventory request") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(attempts) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedInventoryRequest {
            return CappedInventoryRequest(
                code: code,
                label: label,
                capacity: capacity,
                procedureCode: procedureCode,
                tags: tags,
                approved: approved,
                bed: bed,
                attempts: attempts,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped inventory request in status planned.
    static func newCappedInventoryRequest(_ code: String, label: String) -> CappedInventoryRequest {
        return CappedInventoryRequest(
            code: code,
            label: label,
            capacity: 0,
            procedureCode: "",
            tags: [],
            approved: false,
            bed: "",
            attempts: 0,
            currency: "",
            status: CappedInventoryRequestStatus.planned
        )
    }
}
