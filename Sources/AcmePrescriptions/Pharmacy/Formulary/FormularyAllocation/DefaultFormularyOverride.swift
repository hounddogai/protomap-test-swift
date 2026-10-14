import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default formulary override is in its life cycle.
    enum DefaultFormularyOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One default formulary override, with what the planners need to act on it.
    final class DefaultFormularyOverride {
        var code: String
        var name: String
        var updatedAt: Int
        var limit: Int
        var windowDays: Int
        var archived: Bool
        var ward: String
        var dosageMg: Double
        var durationMinutes: Int
        var status: DefaultFormularyOverrideStatus

        init(code: String, name: String, updatedAt: Int, limit: Int, windowDays: Int, archived: Bool, ward: String, dosageMg: Double, durationMinutes: Int, status: DefaultFormularyOverrideStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.limit = limit
            self.windowDays = windowDays
            self.archived = archived
            self.ward = ward
            self.dosageMg = dosageMg
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: DefaultFormularyOverrideStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
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
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DefaultFormularyOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultFormularyOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default formulary override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (Double(durationMinutes) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> DefaultFormularyOverride {
            return DefaultFormularyOverride(
                code: code,
                name: name,
                updatedAt: updatedAt,
                limit: limit,
                windowDays: windowDays,
                archived: archived,
                ward: ward,
                dosageMg: dosageMg,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default formulary override in status planned.
    static func newDefaultFormularyOverride(_ code: String, name: String) -> DefaultFormularyOverride {
        return DefaultFormularyOverride(
            code: code,
            name: name,
            updatedAt: 0,
            limit: 0,
            windowDays: 0,
            archived: false,
            ward: "",
            dosageMg: 0.0,
            durationMinutes: 0,
            status: DefaultFormularyOverrideStatus.planned
        )
    }
}
