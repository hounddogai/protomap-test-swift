import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range assignment is in its life cycle.
    enum LenientReferenceRangeAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient reference range assignment. Its code is unique within a tenant.
    final class LenientReferenceRangeAssignment {
        var code: String
        var label: String
        var visible: Bool
        var patientRef: String
        var weight: Double
        var capacity: Int
        var status: LenientReferenceRangeAssignmentStatus

        init(code: String, label: String, visible: Bool, patientRef: String, weight: Double, capacity: Int, status: LenientReferenceRangeAssignmentStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.patientRef = patientRef
            self.weight = weight
            self.capacity = capacity
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

        func canMoveTo(_ next: LenientReferenceRangeAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LenientReferenceRangeAssignmentStatus.revoked || next == LenientReferenceRangeAssignmentStatus.expired
            case .revoked:
                return next == LenientReferenceRangeAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReferenceRangeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient reference range assignment") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + weight) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeAssignment {
            return LenientReferenceRangeAssignment(
                code: code,
                label: label,
                visible: visible,
                patientRef: patientRef,
                weight: weight,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient reference range assignment in status requested.
    static func newLenientReferenceRangeAssignment(_ code: String, label: String) -> LenientReferenceRangeAssignment {
        return LenientReferenceRangeAssignment(
            code: code,
            label: label,
            visible: false,
            patientRef: "",
            weight: 0.0,
            capacity: 0,
            status: LenientReferenceRangeAssignmentStatus.requested
        )
    }
}
