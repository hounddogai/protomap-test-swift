import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual charge override is in its life cycle.
    enum ManualChargeOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual charge override and its current status.
    final class ManualChargeOverride {
        var code: String
        var name: String
        var category: String
        var description: String
        var patientRef: String
        var weight: Double
        var timezone: String
        var durationMinutes: Int
        var acuity: Int
        var status: ManualChargeOverrideStatus

        init(code: String, name: String, category: String, description: String, patientRef: String, weight: Double, timezone: String, durationMinutes: Int, acuity: Int, status: ManualChargeOverrideStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.description = description
            self.patientRef = patientRef
            self.weight = weight
            self.timezone = timezone
            self.durationMinutes = durationMinutes
            self.acuity = acuity
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

        func canMoveTo(_ next: ManualChargeOverrideStatus) -> Bool {
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
                return next == ManualChargeOverrideStatus.ready || next == ManualChargeOverrideStatus.draining
            case .ready:
                return next == ManualChargeOverrideStatus.draining || next == ManualChargeOverrideStatus.stopped
            case .draining:
                return next == ManualChargeOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualChargeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual charge override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((Double(acuity) + weight) * 100).rounded() / 100
        }

        func copyValue() -> ManualChargeOverride {
            return ManualChargeOverride(
                code: code,
                name: name,
                category: category,
                description: description,
                patientRef: patientRef,
                weight: weight,
                timezone: timezone,
                durationMinutes: durationMinutes,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual charge override in status idle.
    static func newManualChargeOverride(_ code: String, name: String) -> ManualChargeOverride {
        return ManualChargeOverride(
            code: code,
            name: name,
            category: "",
            description: "",
            patientRef: "",
            weight: 0.0,
            timezone: "",
            durationMinutes: 0,
            acuity: 0,
            status: ManualChargeOverrideStatus.idle
        )
    }
}
