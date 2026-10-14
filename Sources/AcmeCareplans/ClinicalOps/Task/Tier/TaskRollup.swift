import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task rollup is in its life cycle.
    enum TaskRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A task rollup. Its code is unique within a tenant.
    final class TaskRollup {
        var code: String
        var title: String
        var dosageMg: Double
        var windowDays: Int
        var startsAt: Int
        var phone: String
        var expiresAt: Int
        var approved: Bool
        var status: TaskRollupStatus

        init(code: String, title: String, dosageMg: Double, windowDays: Int, startsAt: Int, phone: String, expiresAt: Int, approved: Bool, status: TaskRollupStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.phone = phone
            self.expiresAt = expiresAt
            self.approved = approved
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

        func canMoveTo(_ next: TaskRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TaskRollupStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TaskRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((Double(windowDays) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TaskRollup {
            return TaskRollup(
                code: code,
                title: title,
                dosageMg: dosageMg,
                windowDays: windowDays,
                startsAt: startsAt,
                phone: phone,
                expiresAt: expiresAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task rollup in status idle.
    static func newTaskRollup(_ code: String, title: String) -> TaskRollup {
        return TaskRollup(
            code: code,
            title: title,
            dosageMg: 0.0,
            windowDays: 0,
            startsAt: 0,
            phone: "",
            expiresAt: 0,
            approved: false,
            status: TaskRollupStatus.idle
        )
    }
}
