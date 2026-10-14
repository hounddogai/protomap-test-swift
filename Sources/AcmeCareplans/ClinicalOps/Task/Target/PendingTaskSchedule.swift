import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending task schedule is in its life cycle.
    enum PendingTaskScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending task schedule. Its code is unique within a tenant.
    final class PendingTaskSchedule {
        var code: String
        var title: String
        var revision: Int
        var approved: Bool
        var endsAt: Int
        var allergy: String
        var currency: String
        var tags: [String]
        var category: String
        var ward: String
        var amount: Double
        var status: PendingTaskScheduleStatus

        init(code: String, title: String, revision: Int, approved: Bool, endsAt: Int, allergy: String, currency: String, tags: [String], category: String, ward: String, amount: Double, status: PendingTaskScheduleStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.approved = approved
            self.endsAt = endsAt
            self.allergy = allergy
            self.currency = currency
            self.tags = tags
            self.category = category
            self.ward = ward
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingTaskScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingTaskScheduleStatus.ready
            case .ready:
                return next == PendingTaskScheduleStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingTaskScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending task schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return (amount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> PendingTaskSchedule {
            return PendingTaskSchedule(
                code: code,
                title: title,
                revision: revision,
                approved: approved,
                endsAt: endsAt,
                allergy: allergy,
                currency: currency,
                tags: tags,
                category: category,
                ward: ward,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending task schedule in status idle.
    static func newPendingTaskSchedule(_ code: String, title: String) -> PendingTaskSchedule {
        return PendingTaskSchedule(
            code: code,
            title: title,
            revision: 0,
            approved: false,
            endsAt: 0,
            allergy: "",
            currency: "",
            tags: [],
            category: "",
            ward: "",
            amount: 0.0,
            status: PendingTaskScheduleStatus.idle
        )
    }
}
