import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending outreach checkpoint is in its life cycle.
    enum PendingOutreachCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a pending outreach checkpoint and its current status.
    final class PendingOutreachCheckpoint {
        var code: String
        var label: String
        var visitMinutes: Int
        var minimum: Double
        var tags: [String]
        var createdAt: Int
        var category: String
        var source: String
        var status: PendingOutreachCheckpointStatus

        init(code: String, label: String, visitMinutes: Int, minimum: Double, tags: [String], createdAt: Int, category: String, source: String, status: PendingOutreachCheckpointStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.tags = tags
            self.createdAt = createdAt
            self.category = category
            self.source = source
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

        func canMoveTo(_ next: PendingOutreachCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingOutreachCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending outreach checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (Double(createdAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> PendingOutreachCheckpoint {
            return PendingOutreachCheckpoint(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                minimum: minimum,
                tags: tags,
                createdAt: createdAt,
                category: category,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending outreach checkpoint in status proposed.
    static func newPendingOutreachCheckpoint(_ code: String, label: String) -> PendingOutreachCheckpoint {
        return PendingOutreachCheckpoint(
            code: code,
            label: label,
            visitMinutes: 0,
            minimum: 0.0,
            tags: [],
            createdAt: 0,
            category: "",
            source: "",
            status: PendingOutreachCheckpointStatus.proposed
        )
    }
}
