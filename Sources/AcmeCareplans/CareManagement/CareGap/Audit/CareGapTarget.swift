import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap target is in its life cycle.
    enum CareGapTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care gap target. Its code is unique within a tenant.
    final class CareGapTarget {
        var code: String
        var name: String
        var reviewer: String
        var capacity: Int
        var createdAt: Int
        var visitMinutes: Int
        var status: CareGapTargetStatus

        init(code: String, name: String, reviewer: String, capacity: Int, createdAt: Int, visitMinutes: Int, status: CareGapTargetStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.capacity = capacity
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CareGapTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareGapTargetStatus.pending || next == CareGapTargetStatus.closed
            case .pending:
                return next == CareGapTargetStatus.suspended || next == CareGapTargetStatus.closed
            case .active:
                return next == CareGapTargetStatus.closed
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

        func moveTo(_ next: CareGapTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return ((Double(visitMinutes) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapTarget {
            return CareGapTarget(
                code: code,
                name: name,
                reviewer: reviewer,
                capacity: capacity,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap target in status draft.
    static func newCareGapTarget(_ code: String, name: String) -> CareGapTarget {
        return CareGapTarget(
            code: code,
            name: name,
            reviewer: "",
            capacity: 0,
            createdAt: 0,
            visitMinutes: 0,
            status: CareGapTargetStatus.draft
        )
    }
}
