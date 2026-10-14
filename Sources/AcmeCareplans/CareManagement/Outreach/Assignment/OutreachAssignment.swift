import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach assignment is in its life cycle.
    enum OutreachAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A outreach assignment. Its code is unique within a tenant.
    final class OutreachAssignment {
        var code: String
        var label: String
        var locale: String
        var threshold: Double
        var maximum: Double
        var expiresAt: Int
        var facility: String
        var status: OutreachAssignmentStatus

        init(code: String, label: String, locale: String, threshold: Double, maximum: Double, expiresAt: Int, facility: String, status: OutreachAssignmentStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.threshold = threshold
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.facility = facility
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

        func canMoveTo(_ next: OutreachAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == OutreachAssignmentStatus.pending || next == OutreachAssignmentStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OutreachAssignmentStatus.closed
            case .suspended:
                return next == OutreachAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return ((threshold - maximum) * 100).rounded() / 100
        }

        func copyValue() -> OutreachAssignment {
            return OutreachAssignment(
                code: code,
                label: label,
                locale: locale,
                threshold: threshold,
                maximum: maximum,
                expiresAt: expiresAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a outreach assignment in status draft.
    static func newOutreachAssignment(_ code: String, label: String) -> OutreachAssignment {
        return OutreachAssignment(
            code: code,
            label: label,
            locale: "",
            threshold: 0.0,
            maximum: 0.0,
            expiresAt: 0,
            facility: "",
            status: OutreachAssignmentStatus.draft
        )
    }
}
