import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled isolation policy is in its life cycle.
    enum ScheduledIsolationPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled isolation policy and its current status.
    final class ScheduledIsolationPolicy {
        var code: String
        var name: String
        var durationMinutes: Int
        var diagnosisCode: String
        var visible: Bool
        var expiresAt: Int
        var allergy: String
        var category: String
        var status: ScheduledIsolationPolicyStatus

        init(code: String, name: String, durationMinutes: Int, diagnosisCode: String, visible: Bool, expiresAt: Int, allergy: String, category: String, status: ScheduledIsolationPolicyStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.category = category
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

        func canMoveTo(_ next: ScheduledIsolationPolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledIsolationPolicyStatus.ready || next == ScheduledIsolationPolicyStatus.stopped
            case .warming:
                return next == ScheduledIsolationPolicyStatus.ready || next == ScheduledIsolationPolicyStatus.stopped
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

        func moveTo(_ next: ScheduledIsolationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled isolation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(durationMinutes) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledIsolationPolicy {
            return ScheduledIsolationPolicy(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                visible: visible,
                expiresAt: expiresAt,
                allergy: allergy,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled isolation policy in status idle.
    static func newScheduledIsolationPolicy(_ code: String, name: String) -> ScheduledIsolationPolicy {
        return ScheduledIsolationPolicy(
            code: code,
            name: name,
            durationMinutes: 0,
            diagnosisCode: "",
            visible: false,
            expiresAt: 0,
            allergy: "",
            category: "",
            status: ScheduledIsolationPolicyStatus.idle
        )
    }
}
