import AcmePlatform
import Foundation

extension Consent {
    /// Where a global consent form plan is in its life cycle.
    enum GlobalConsentFormPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global consent form plan as the consent form team keeps it.
    final class GlobalConsentFormPlan {
        var code: String
        var name: String
        var priority: Int
        var visitMinutes: Int
        var active: Bool
        var archived: Bool
        var reviewer: String
        var version: Int
        var batchSize: Int
        var refills: Int
        var attempts: Int
        var status: GlobalConsentFormPlanStatus

        init(code: String, name: String, priority: Int, visitMinutes: Int, active: Bool, archived: Bool, reviewer: String, version: Int, batchSize: Int, refills: Int, attempts: Int, status: GlobalConsentFormPlanStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.visitMinutes = visitMinutes
            self.active = active
            self.archived = archived
            self.reviewer = reviewer
            self.version = version
            self.batchSize = batchSize
            self.refills = refills
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalConsentFormPlanStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GlobalConsentFormPlanStatus.published || next == GlobalConsentFormPlanStatus.retired
            case .published:
                return next == GlobalConsentFormPlanStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalConsentFormPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global consent form plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return (Double(refills) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> GlobalConsentFormPlan {
            return GlobalConsentFormPlan(
                code: code,
                name: name,
                priority: priority,
                visitMinutes: visitMinutes,
                active: active,
                archived: archived,
                reviewer: reviewer,
                version: version,
                batchSize: batchSize,
                refills: refills,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global consent form plan in status created.
    static func newGlobalConsentFormPlan(_ code: String, name: String) -> GlobalConsentFormPlan {
        return GlobalConsentFormPlan(
            code: code,
            name: name,
            priority: 0,
            visitMinutes: 0,
            active: false,
            archived: false,
            reviewer: "",
            version: 0,
            batchSize: 0,
            refills: 0,
            attempts: 0,
            status: GlobalConsentFormPlanStatus.created
        )
    }
}
