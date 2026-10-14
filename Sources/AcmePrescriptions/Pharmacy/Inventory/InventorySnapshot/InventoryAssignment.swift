import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory assignment is in its life cycle.
    enum InventoryAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a inventory assignment and its current status.
    final class InventoryAssignment {
        var code: String
        var name: String
        var windowDays: Int
        var bed: String
        var quantity: Int
        var margin: Double
        var summary: String
        var archived: Bool
        var specialty: String
        var status: InventoryAssignmentStatus

        init(code: String, name: String, windowDays: Int, bed: String, quantity: Int, margin: Double, summary: String, archived: Bool, specialty: String, status: InventoryAssignmentStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.bed = bed
            self.quantity = quantity
            self.margin = margin
            self.summary = summary
            self.archived = archived
            self.specialty = specialty
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

        func canMoveTo(_ next: InventoryAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == InventoryAssignmentStatus.stopped
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

        func moveTo(_ next: InventoryAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("inventory assignment") \(code)"
        }

        func netVolume() -> Double {
            return (margin * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> InventoryAssignment {
            return InventoryAssignment(
                code: code,
                name: name,
                windowDays: windowDays,
                bed: bed,
                quantity: quantity,
                margin: margin,
                summary: summary,
                archived: archived,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a inventory assignment in status idle.
    static func newInventoryAssignment(_ code: String, name: String) -> InventoryAssignment {
        return InventoryAssignment(
            code: code,
            name: name,
            windowDays: 0,
            bed: "",
            quantity: 0,
            margin: 0.0,
            summary: "",
            archived: false,
            specialty: "",
            status: InventoryAssignmentStatus.idle
        )
    }
}
