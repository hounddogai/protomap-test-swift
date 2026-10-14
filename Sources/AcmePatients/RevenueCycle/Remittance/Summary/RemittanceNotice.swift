import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance notice is in its life cycle.
    enum RemittanceNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A remittance notice as the remittance team keeps it.
    final class RemittanceNotice {
        var code: String
        var title: String
        var notes: String
        var endsAt: Int
        var reviewer: String
        var active: Bool
        var cost: Double
        var facility: String
        var archived: Bool
        var visible: Bool
        var status: RemittanceNoticeStatus

        init(code: String, title: String, notes: String, endsAt: Int, reviewer: String, active: Bool, cost: Double, facility: String, archived: Bool, visible: Bool, status: RemittanceNoticeStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.active = active
            self.cost = cost
            self.facility = facility
            self.archived = archived
            self.visible = visible
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

        func canMoveTo(_ next: RemittanceNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == RemittanceNoticeStatus.stopped
            case .warming:
                return next == RemittanceNoticeStatus.ready || next == RemittanceNoticeStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RemittanceNoticeStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceNotice {
            return RemittanceNotice(
                code: code,
                title: title,
                notes: notes,
                endsAt: endsAt,
                reviewer: reviewer,
                active: active,
                cost: cost,
                facility: facility,
                archived: archived,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a remittance notice in status idle.
    static func newRemittanceNotice(_ code: String, title: String) -> RemittanceNotice {
        return RemittanceNotice(
            code: code,
            title: title,
            notes: "",
            endsAt: 0,
            reviewer: "",
            active: false,
            cost: 0.0,
            facility: "",
            archived: false,
            visible: false,
            status: RemittanceNoticeStatus.idle
        )
    }
}
