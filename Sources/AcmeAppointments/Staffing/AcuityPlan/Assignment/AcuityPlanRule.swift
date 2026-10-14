import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan rule is in its life cycle.
    enum AcuityPlanRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a acuity plan rule and its current status.
    final class AcuityPlanRule {
        var code: String
        var name: String
        var copay: Double
        var revision: Int
        var active: Bool
        var notes: String
        var ownerID: String
        var capacity: Int
        var status: AcuityPlanRuleStatus

        init(code: String, name: String, copay: Double, revision: Int, active: Bool, notes: String, ownerID: String, capacity: Int, status: AcuityPlanRuleStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.revision = revision
            self.active = active
            self.notes = notes
            self.ownerID = ownerID
            self.capacity = capacity
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

        func canMoveTo(_ next: AcuityPlanRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AcuityPlanRuleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return ((Double(revision) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanRule {
            return AcuityPlanRule(
                code: code,
                name: name,
                copay: copay,
                revision: revision,
                active: active,
                notes: notes,
                ownerID: ownerID,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan rule in status requested.
    static func newAcuityPlanRule(_ code: String, name: String) -> AcuityPlanRule {
        return AcuityPlanRule(
            code: code,
            name: name,
            copay: 0.0,
            revision: 0,
            active: false,
            notes: "",
            ownerID: "",
            capacity: 0,
            status: AcuityPlanRuleStatus.requested
        )
    }
}
