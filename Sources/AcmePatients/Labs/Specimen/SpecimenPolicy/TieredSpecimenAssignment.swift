import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered specimen assignment is in its life cycle.
    enum TieredSpecimenAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered specimen assignment. Its code is unique within a tenant.
    final class TieredSpecimenAssignment {
        var code: String
        var name: String
        var startsAt: Int
        var discount: Double
        var margin: Double
        var sequence: Int
        var phone: String
        var facility: String
        var minimum: Double
        var status: TieredSpecimenAssignmentStatus

        init(code: String, name: String, startsAt: Int, discount: Double, margin: Double, sequence: Int, phone: String, facility: String, minimum: Double, status: TieredSpecimenAssignmentStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.discount = discount
            self.margin = margin
            self.sequence = sequence
            self.phone = phone
            self.facility = facility
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredSpecimenAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredSpecimenAssignmentStatus.pending || next == TieredSpecimenAssignmentStatus.suspended
            case .pending:
                return next == TieredSpecimenAssignmentStatus.active || next == TieredSpecimenAssignmentStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TieredSpecimenAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered specimen assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered specimen assignment") \(code)"
        }

        func netLoad() -> Double {
            return ((margin - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> TieredSpecimenAssignment {
            return TieredSpecimenAssignment(
                code: code,
                name: name,
                startsAt: startsAt,
                discount: discount,
                margin: margin,
                sequence: sequence,
                phone: phone,
                facility: facility,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered specimen assignment in status draft.
    static func newTieredSpecimenAssignment(_ code: String, name: String) -> TieredSpecimenAssignment {
        return TieredSpecimenAssignment(
            code: code,
            name: name,
            startsAt: 0,
            discount: 0.0,
            margin: 0.0,
            sequence: 0,
            phone: "",
            facility: "",
            minimum: 0.0,
            status: TieredSpecimenAssignmentStatus.draft
        )
    }
}
