import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback outreach assignment is in its life cycle.
    enum FallbackOutreachAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback outreach assignment, with what the planners need to act on it.
    final class FallbackOutreachAssignment {
        var code: String
        var label: String
        var ward: String
        var acuity: Int
        var archived: Bool
        var segment: String
        var minimum: Double
        var durationMinutes: Int
        var quantity: Int
        var status: FallbackOutreachAssignmentStatus

        init(code: String, label: String, ward: String, acuity: Int, archived: Bool, segment: String, minimum: Double, durationMinutes: Int, quantity: Int, status: FallbackOutreachAssignmentStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.acuity = acuity
            self.archived = archived
            self.segment = segment
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackOutreachAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackOutreachAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackOutreachAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback outreach assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return (Double(durationMinutes) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOutreachAssignment {
            return FallbackOutreachAssignment(
                code: code,
                label: label,
                ward: ward,
                acuity: acuity,
                archived: archived,
                segment: segment,
                minimum: minimum,
                durationMinutes: durationMinutes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback outreach assignment in status requested.
    static func newFallbackOutreachAssignment(_ code: String, label: String) -> FallbackOutreachAssignment {
        return FallbackOutreachAssignment(
            code: code,
            label: label,
            ward: "",
            acuity: 0,
            archived: false,
            segment: "",
            minimum: 0.0,
            durationMinutes: 0,
            quantity: 0,
            status: FallbackOutreachAssignmentStatus.requested
        )
    }
}
