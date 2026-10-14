import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual outreach assignment is in its life cycle.
    enum ManualOutreachAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual outreach assignment. Its code is unique within a tenant.
    final class ManualOutreachAssignment {
        var code: String
        var label: String
        var endsAt: Int
        var rate: Double
        var maximum: Double
        var name: String
        var durationMinutes: Int
        var attributes: [String: String]
        var score: Double
        var status: ManualOutreachAssignmentStatus

        init(code: String, label: String, endsAt: Int, rate: Double, maximum: Double, name: String, durationMinutes: Int, attributes: [String: String], score: Double, status: ManualOutreachAssignmentStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.rate = rate
            self.maximum = maximum
            self.name = name
            self.durationMinutes = durationMinutes
            self.attributes = attributes
            self.score = score
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

        func canMoveTo(_ next: ManualOutreachAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualOutreachAssignmentStatus.approved
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualOutreachAssignmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualOutreachAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual outreach assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual outreach assignment") \(code)"
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

        func projectedLoad() -> Double {
            return ((score + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ManualOutreachAssignment {
            return ManualOutreachAssignment(
                code: code,
                label: label,
                endsAt: endsAt,
                rate: rate,
                maximum: maximum,
                name: name,
                durationMinutes: durationMinutes,
                attributes: attributes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual outreach assignment in status proposed.
    static func newManualOutreachAssignment(_ code: String, label: String) -> ManualOutreachAssignment {
        return ManualOutreachAssignment(
            code: code,
            label: label,
            endsAt: 0,
            rate: 0.0,
            maximum: 0.0,
            name: "",
            durationMinutes: 0,
            attributes: [:],
            score: 0.0,
            status: ManualOutreachAssignmentStatus.proposed
        )
    }
}
