import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional outreach allocation is in its life cycle.
    enum RegionalOutreachAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional outreach allocation and its current status.
    final class RegionalOutreachAllocation {
        var code: String
        var label: String
        var revision: Int
        var threshold: Double
        var description: String
        var timezone: String
        var pinned: Bool
        var sequence: Int
        var title: String
        var active: Bool
        var createdAt: Int
        var status: RegionalOutreachAllocationStatus

        init(code: String, label: String, revision: Int, threshold: Double, description: String, timezone: String, pinned: Bool, sequence: Int, title: String, active: Bool, createdAt: Int, status: RegionalOutreachAllocationStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.threshold = threshold
            self.description = description
            self.timezone = timezone
            self.pinned = pinned
            self.sequence = sequence
            self.title = title
            self.active = active
            self.createdAt = createdAt
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

        func canMoveTo(_ next: RegionalOutreachAllocationStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalOutreachAllocationStatus.pending
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RegionalOutreachAllocationStatus.closed
            case .suspended:
                return next == RegionalOutreachAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOutreachAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional outreach allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return (threshold * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOutreachAllocation {
            return RegionalOutreachAllocation(
                code: code,
                label: label,
                revision: revision,
                threshold: threshold,
                description: description,
                timezone: timezone,
                pinned: pinned,
                sequence: sequence,
                title: title,
                active: active,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional outreach allocation in status draft.
    static func newRegionalOutreachAllocation(_ code: String, label: String) -> RegionalOutreachAllocation {
        return RegionalOutreachAllocation(
            code: code,
            label: label,
            revision: 0,
            threshold: 0.0,
            description: "",
            timezone: "",
            pinned: false,
            sequence: 0,
            title: "",
            active: false,
            createdAt: 0,
            status: RegionalOutreachAllocationStatus.draft
        )
    }
}
