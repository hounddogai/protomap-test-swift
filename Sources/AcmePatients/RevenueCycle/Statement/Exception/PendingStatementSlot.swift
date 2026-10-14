import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending statement slot is in its life cycle.
    enum PendingStatementSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending statement slot. Its code is unique within a tenant.
    final class PendingStatementSlot {
        var code: String
        var title: String
        var active: Bool
        var threshold: Double
        var description: String
        var facility: String
        var margin: Double
        var visitMinutes: Int
        var sequence: Int
        var archived: Bool
        var status: PendingStatementSlotStatus

        init(code: String, title: String, active: Bool, threshold: Double, description: String, facility: String, margin: Double, visitMinutes: Int, sequence: Int, archived: Bool, status: PendingStatementSlotStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.threshold = threshold
            self.description = description
            self.facility = facility
            self.margin = margin
            self.visitMinutes = visitMinutes
            self.sequence = sequence
            self.archived = archived
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

        func canMoveTo(_ next: PendingStatementSlotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PendingStatementSlotStatus.published
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

        func moveTo(_ next: PendingStatementSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending statement slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending statement slot") \(code)"
        }

        func netValue() -> Double {
            return ((Double(visitMinutes) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PendingStatementSlot {
            return PendingStatementSlot(
                code: code,
                title: title,
                active: active,
                threshold: threshold,
                description: description,
                facility: facility,
                margin: margin,
                visitMinutes: visitMinutes,
                sequence: sequence,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending statement slot in status created.
    static func newPendingStatementSlot(_ code: String, title: String) -> PendingStatementSlot {
        return PendingStatementSlot(
            code: code,
            title: title,
            active: false,
            threshold: 0.0,
            description: "",
            facility: "",
            margin: 0.0,
            visitMinutes: 0,
            sequence: 0,
            archived: false,
            status: PendingStatementSlotStatus.created
        )
    }
}
