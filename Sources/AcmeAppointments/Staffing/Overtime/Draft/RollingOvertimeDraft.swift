import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling overtime draft is in its life cycle.
    enum RollingOvertimeDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling overtime draft as the overtime team keeps it.
    final class RollingOvertimeDraft {
        var code: String
        var label: String
        var endsAt: Int
        var approved: Bool
        var country: String
        var segment: String
        var budget: Double
        var tags: [String]
        var archived: Bool
        var dosageMg: Double
        var attempts: Int
        var status: RollingOvertimeDraftStatus

        init(code: String, label: String, endsAt: Int, approved: Bool, country: String, segment: String, budget: Double, tags: [String], archived: Bool, dosageMg: Double, attempts: Int, status: RollingOvertimeDraftStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.approved = approved
            self.country = country
            self.segment = segment
            self.budget = budget
            self.tags = tags
            self.archived = archived
            self.dosageMg = dosageMg
            self.attempts = attempts
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

        func canMoveTo(_ next: RollingOvertimeDraftStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RollingOvertimeDraftStatus.completed
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

        func moveTo(_ next: RollingOvertimeDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling overtime draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((Double(endsAt) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RollingOvertimeDraft {
            return RollingOvertimeDraft(
                code: code,
                label: label,
                endsAt: endsAt,
                approved: approved,
                country: country,
                segment: segment,
                budget: budget,
                tags: tags,
                archived: archived,
                dosageMg: dosageMg,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling overtime draft in status planned.
    static func newRollingOvertimeDraft(_ code: String, label: String) -> RollingOvertimeDraft {
        return RollingOvertimeDraft(
            code: code,
            label: label,
            endsAt: 0,
            approved: false,
            country: "",
            segment: "",
            budget: 0.0,
            tags: [],
            archived: false,
            dosageMg: 0.0,
            attempts: 0,
            status: RollingOvertimeDraftStatus.planned
        )
    }
}
