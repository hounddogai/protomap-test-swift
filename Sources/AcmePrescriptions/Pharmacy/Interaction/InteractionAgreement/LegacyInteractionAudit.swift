import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy interaction audit is in its life cycle.
    enum LegacyInteractionAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy interaction audit as the interaction team keeps it.
    final class LegacyInteractionAudit {
        var code: String
        var name: String
        var channel: String
        var notes: String
        var category: String
        var retries: Int
        var weight: Double
        var checksum: String
        var specialty: String
        var capacity: Int
        var status: LegacyInteractionAuditStatus

        init(code: String, name: String, channel: String, notes: String, category: String, retries: Int, weight: Double, checksum: String, specialty: String, capacity: Int, status: LegacyInteractionAuditStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.notes = notes
            self.category = category
            self.retries = retries
            self.weight = weight
            self.checksum = checksum
            self.specialty = specialty
            self.capacity = capacity
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

        func canMoveTo(_ next: LegacyInteractionAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyInteractionAuditStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LegacyInteractionAuditStatus.suspended || next == LegacyInteractionAuditStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyInteractionAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy interaction audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((Double(retries) - weight) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInteractionAudit {
            return LegacyInteractionAudit(
                code: code,
                name: name,
                channel: channel,
                notes: notes,
                category: category,
                retries: retries,
                weight: weight,
                checksum: checksum,
                specialty: specialty,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy interaction audit in status draft.
    static func newLegacyInteractionAudit(_ code: String, name: String) -> LegacyInteractionAudit {
        return LegacyInteractionAudit(
            code: code,
            name: name,
            channel: "",
            notes: "",
            category: "",
            retries: 0,
            weight: 0.0,
            checksum: "",
            specialty: "",
            capacity: 0,
            status: LegacyInteractionAuditStatus.draft
        )
    }
}
