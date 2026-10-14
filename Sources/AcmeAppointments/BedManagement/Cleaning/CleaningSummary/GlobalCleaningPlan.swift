import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global cleaning plan is in its life cycle.
    enum GlobalCleaningPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global cleaning plan as the cleaning team keeps it.
    final class GlobalCleaningPlan {
        var code: String
        var title: String
        var description: String
        var channel: String
        var ceiling: Double
        var category: String
        var diagnosisCode: String
        var status: GlobalCleaningPlanStatus

        init(code: String, title: String, description: String, channel: String, ceiling: Double, category: String, diagnosisCode: String, status: GlobalCleaningPlanStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.channel = channel
            self.ceiling = ceiling
            self.category = category
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalCleaningPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalCleaningPlanStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalCleaningPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global cleaning plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> GlobalCleaningPlan {
            return GlobalCleaningPlan(
                code: code,
                title: title,
                description: description,
                channel: channel,
                ceiling: ceiling,
                category: category,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global cleaning plan in status requested.
    static func newGlobalCleaningPlan(_ code: String, title: String) -> GlobalCleaningPlan {
        return GlobalCleaningPlan(
            code: code,
            title: title,
            description: "",
            channel: "",
            ceiling: 0.0,
            category: "",
            diagnosisCode: "",
            status: GlobalCleaningPlanStatus.requested
        )
    }
}
