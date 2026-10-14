import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict panel assignment is in its life cycle.
    enum StrictPanelAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict panel assignment and its current status.
    final class StrictPanelAssignment {
        var code: String
        var title: String
        var category: String
        var expiresAt: Int
        var notes: String
        var name: String
        var cost: Double
        var pinned: Bool
        var batchSize: Int
        var facility: String
        var endsAt: Int
        var status: StrictPanelAssignmentStatus

        init(code: String, title: String, category: String, expiresAt: Int, notes: String, name: String, cost: Double, pinned: Bool, batchSize: Int, facility: String, endsAt: Int, status: StrictPanelAssignmentStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.expiresAt = expiresAt
            self.notes = notes
            self.name = name
            self.cost = cost
            self.pinned = pinned
            self.batchSize = batchSize
            self.facility = facility
            self.endsAt = endsAt
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

        func canMoveTo(_ next: StrictPanelAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictPanelAssignmentStatus.approved || next == StrictPanelAssignmentStatus.rejected
            case .approved:
                return next == StrictPanelAssignmentStatus.rejected || next == StrictPanelAssignmentStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictPanelAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict panel assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((cost + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictPanelAssignment {
            return StrictPanelAssignment(
                code: code,
                title: title,
                category: category,
                expiresAt: expiresAt,
                notes: notes,
                name: name,
                cost: cost,
                pinned: pinned,
                batchSize: batchSize,
                facility: facility,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict panel assignment in status proposed.
    static func newStrictPanelAssignment(_ code: String, title: String) -> StrictPanelAssignment {
        return StrictPanelAssignment(
            code: code,
            title: title,
            category: "",
            expiresAt: 0,
            notes: "",
            name: "",
            cost: 0.0,
            pinned: false,
            batchSize: 0,
            facility: "",
            endsAt: 0,
            status: StrictPanelAssignmentStatus.proposed
        )
    }
}
