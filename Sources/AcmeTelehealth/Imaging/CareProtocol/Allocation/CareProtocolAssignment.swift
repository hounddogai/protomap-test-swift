import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol assignment is in its life cycle.
    enum CareProtocolAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care protocol assignment, with what the planners need to act on it.
    final class CareProtocolAssignment {
        var code: String
        var label: String
        var capacity: Int
        var sequence: Int
        var approved: Bool
        var copay: Double
        var quantity: Int
        var ceiling: Double
        var status: CareProtocolAssignmentStatus

        init(code: String, label: String, capacity: Int, sequence: Int, approved: Bool, copay: Double, quantity: Int, ceiling: Double, status: CareProtocolAssignmentStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.sequence = sequence
            self.approved = approved
            self.copay = copay
            self.quantity = quantity
            self.ceiling = ceiling
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

        func canMoveTo(_ next: CareProtocolAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CareProtocolAssignmentStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CareProtocolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return (Double(quantity) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAssignment {
            return CareProtocolAssignment(
                code: code,
                label: label,
                capacity: capacity,
                sequence: sequence,
                approved: approved,
                copay: copay,
                quantity: quantity,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol assignment in status new.
    static func newCareProtocolAssignment(_ code: String, label: String) -> CareProtocolAssignment {
        return CareProtocolAssignment(
            code: code,
            label: label,
            capacity: 0,
            sequence: 0,
            approved: false,
            copay: 0.0,
            quantity: 0,
            ceiling: 0.0,
            status: CareProtocolAssignmentStatus.new
        )
    }
}
