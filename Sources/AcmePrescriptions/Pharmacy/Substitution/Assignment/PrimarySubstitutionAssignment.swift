import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary substitution assignment is in its life cycle.
    enum PrimarySubstitutionAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary substitution assignment, with what the planners need to act on it.
    final class PrimarySubstitutionAssignment {
        var code: String
        var label: String
        var ward: String
        var country: String
        var revision: Int
        var archived: Bool
        var allergy: String
        var quantity: Int
        var retries: Int
        var minimum: Double
        var endsAt: Int
        var status: PrimarySubstitutionAssignmentStatus

        init(code: String, label: String, ward: String, country: String, revision: Int, archived: Bool, allergy: String, quantity: Int, retries: Int, minimum: Double, endsAt: Int, status: PrimarySubstitutionAssignmentStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.country = country
            self.revision = revision
            self.archived = archived
            self.allergy = allergy
            self.quantity = quantity
            self.retries = retries
            self.minimum = minimum
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PrimarySubstitutionAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PrimarySubstitutionAssignmentStatus.ready || next == PrimarySubstitutionAssignmentStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimarySubstitutionAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySubstitutionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary substitution assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("primary substitution assignment") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(revision) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySubstitutionAssignment {
            return PrimarySubstitutionAssignment(
                code: code,
                label: label,
                ward: ward,
                country: country,
                revision: revision,
                archived: archived,
                allergy: allergy,
                quantity: quantity,
                retries: retries,
                minimum: minimum,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary substitution assignment in status idle.
    static func newPrimarySubstitutionAssignment(_ code: String, label: String) -> PrimarySubstitutionAssignment {
        return PrimarySubstitutionAssignment(
            code: code,
            label: label,
            ward: "",
            country: "",
            revision: 0,
            archived: false,
            allergy: "",
            quantity: 0,
            retries: 0,
            minimum: 0.0,
            endsAt: 0,
            status: PrimarySubstitutionAssignmentStatus.idle
        )
    }
}
