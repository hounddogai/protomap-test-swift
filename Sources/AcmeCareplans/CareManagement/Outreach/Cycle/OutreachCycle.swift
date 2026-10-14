import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach cycle is in its life cycle.
    enum OutreachCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A outreach cycle as the outreach team keeps it.
    final class OutreachCycle {
        var code: String
        var name: String
        var revision: Int
        var startsAt: Int
        var phone: String
        var channel: String
        var weight: Double
        var priority: Int
        var budget: Double
        var createdAt: Int
        var checksum: String
        var status: OutreachCycleStatus

        init(code: String, name: String, revision: Int, startsAt: Int, phone: String, channel: String, weight: Double, priority: Int, budget: Double, createdAt: Int, checksum: String, status: OutreachCycleStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.startsAt = startsAt
            self.phone = phone
            self.channel = channel
            self.weight = weight
            self.priority = priority
            self.budget = budget
            self.createdAt = createdAt
            self.checksum = checksum
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

        func canMoveTo(_ next: OutreachCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == OutreachCycleStatus.rejected || next == OutreachCycleStatus.withdrawn
            case .rejected:
                return next == OutreachCycleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("outreach cycle") \(code)"
        }

        func netTotal() -> Double {
            return ((budget - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachCycle {
            return OutreachCycle(
                code: code,
                name: name,
                revision: revision,
                startsAt: startsAt,
                phone: phone,
                channel: channel,
                weight: weight,
                priority: priority,
                budget: budget,
                createdAt: createdAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a outreach cycle in status proposed.
    static func newOutreachCycle(_ code: String, name: String) -> OutreachCycle {
        return OutreachCycle(
            code: code,
            name: name,
            revision: 0,
            startsAt: 0,
            phone: "",
            channel: "",
            weight: 0.0,
            priority: 0,
            budget: 0.0,
            createdAt: 0,
            checksum: "",
            status: OutreachCycleStatus.proposed
        )
    }
}
