import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure assignment is in its life cycle.
    enum DisclosureAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One disclosure assignment, with what the planners need to act on it.
    final class DisclosureAssignment {
        var code: String
        var label: String
        var locale: String
        var acuity: Int
        var archived: Bool
        var capacity: Int
        var margin: Double
        var region: String
        var status: DisclosureAssignmentStatus

        init(code: String, label: String, locale: String, acuity: Int, archived: Bool, capacity: Int, margin: Double, region: String, status: DisclosureAssignmentStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.acuity = acuity
            self.archived = archived
            self.capacity = capacity
            self.margin = margin
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == DisclosureAssignmentStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DisclosureAssignmentStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DisclosureAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return (margin * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureAssignment {
            return DisclosureAssignment(
                code: code,
                label: label,
                locale: locale,
                acuity: acuity,
                archived: archived,
                capacity: capacity,
                margin: margin,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a disclosure assignment in status planned.
    static func newDisclosureAssignment(_ code: String, label: String) -> DisclosureAssignment {
        return DisclosureAssignment(
            code: code,
            label: label,
            locale: "",
            acuity: 0,
            archived: false,
            capacity: 0,
            margin: 0.0,
            region: "",
            status: DisclosureAssignmentStatus.planned
        )
    }
}
