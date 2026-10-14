import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending task adjustment is in its life cycle.
    enum PendingTaskAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending task adjustment and its current status.
    final class PendingTaskAdjustment {
        var code: String
        var title: String
        var diagnosisCode: String
        var ceiling: Double
        var minimum: Double
        var expiresAt: Int
        var pinned: Bool
        var tags: [String]
        var durationMinutes: Int
        var limit: Int
        var acuity: Int
        var status: PendingTaskAdjustmentStatus

        init(code: String, title: String, diagnosisCode: String, ceiling: Double, minimum: Double, expiresAt: Int, pinned: Bool, tags: [String], durationMinutes: Int, limit: Int, acuity: Int, status: PendingTaskAdjustmentStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.pinned = pinned
            self.tags = tags
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.acuity = acuity
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

        func canMoveTo(_ next: PendingTaskAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingTaskAdjustmentStatus.suspended || next == PendingTaskAdjustmentStatus.closed
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

        func moveTo(_ next: PendingTaskAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending task adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending task adjustment") \(code)"
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
            return ((Double(expiresAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingTaskAdjustment {
            return PendingTaskAdjustment(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                minimum: minimum,
                expiresAt: expiresAt,
                pinned: pinned,
                tags: tags,
                durationMinutes: durationMinutes,
                limit: limit,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending task adjustment in status draft.
    static func newPendingTaskAdjustment(_ code: String, title: String) -> PendingTaskAdjustment {
        return PendingTaskAdjustment(
            code: code,
            title: title,
            diagnosisCode: "",
            ceiling: 0.0,
            minimum: 0.0,
            expiresAt: 0,
            pinned: false,
            tags: [],
            durationMinutes: 0,
            limit: 0,
            acuity: 0,
            status: PendingTaskAdjustmentStatus.draft
        )
    }
}
