import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global goal assignment is in its life cycle.
    enum GlobalGoalAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global goal assignment. Its code is unique within a tenant.
    final class GlobalGoalAssignment {
        var code: String
        var label: String
        var title: String
        var threshold: Double
        var attributes: [String: String]
        var timezone: String
        var capacity: Int
        var pinned: Bool
        var status: GlobalGoalAssignmentStatus

        init(code: String, label: String, title: String, threshold: Double, attributes: [String: String], timezone: String, capacity: Int, pinned: Bool, status: GlobalGoalAssignmentStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.threshold = threshold
            self.attributes = attributes
            self.timezone = timezone
            self.capacity = capacity
            self.pinned = pinned
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

        func canMoveTo(_ next: GlobalGoalAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalGoalAssignmentStatus.withdrawn
            case .approved:
                return next == GlobalGoalAssignmentStatus.rejected || next == GlobalGoalAssignmentStatus.withdrawn
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

        func moveTo(_ next: GlobalGoalAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global goal assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global goal assignment") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedTotal() -> Double {
            return ((threshold + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalGoalAssignment {
            return GlobalGoalAssignment(
                code: code,
                label: label,
                title: title,
                threshold: threshold,
                attributes: attributes,
                timezone: timezone,
                capacity: capacity,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global goal assignment in status proposed.
    static func newGlobalGoalAssignment(_ code: String, label: String) -> GlobalGoalAssignment {
        return GlobalGoalAssignment(
            code: code,
            label: label,
            title: "",
            threshold: 0.0,
            attributes: [:],
            timezone: "",
            capacity: 0,
            pinned: false,
            status: GlobalGoalAssignmentStatus.proposed
        )
    }
}
