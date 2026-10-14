import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global order set assignment is in its life cycle.
    enum GlobalOrderSetAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global order set assignment as the order set team keeps it.
    final class GlobalOrderSetAssignment {
        var code: String
        var name: String
        var timezone: String
        var maximum: Double
        var notes: String
        var quantity: Int
        var endsAt: Int
        var startsAt: Int
        var batchSize: Int
        var status: GlobalOrderSetAssignmentStatus

        init(code: String, name: String, timezone: String, maximum: Double, notes: String, quantity: Int, endsAt: Int, startsAt: Int, batchSize: Int, status: GlobalOrderSetAssignmentStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.maximum = maximum
            self.notes = notes
            self.quantity = quantity
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalOrderSetAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: GlobalOrderSetAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global order set assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return (Double(quantity) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> GlobalOrderSetAssignment {
            return GlobalOrderSetAssignment(
                code: code,
                name: name,
                timezone: timezone,
                maximum: maximum,
                notes: notes,
                quantity: quantity,
                endsAt: endsAt,
                startsAt: startsAt,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global order set assignment in status open.
    static func newGlobalOrderSetAssignment(_ code: String, name: String) -> GlobalOrderSetAssignment {
        return GlobalOrderSetAssignment(
            code: code,
            name: name,
            timezone: "",
            maximum: 0.0,
            notes: "",
            quantity: 0,
            endsAt: 0,
            startsAt: 0,
            batchSize: 0,
            status: GlobalOrderSetAssignmentStatus.`open`
        )
    }
}
