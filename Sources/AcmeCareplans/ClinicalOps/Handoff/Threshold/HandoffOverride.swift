import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff override is in its life cycle.
    enum HandoffOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A handoff override. Its code is unique within a tenant.
    final class HandoffOverride {
        var code: String
        var label: String
        var region: String
        var capacity: Int
        var durationMinutes: Int
        var active: Bool
        var budget: Double
        var externalRef: String
        var segment: String
        var status: HandoffOverrideStatus

        init(code: String, label: String, region: String, capacity: Int, durationMinutes: Int, active: Bool, budget: Double, externalRef: String, segment: String, status: HandoffOverrideStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.active = active
            self.budget = budget
            self.externalRef = externalRef
            self.segment = segment
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

        func canMoveTo(_ next: HandoffOverrideStatus) -> Bool {
            switch status {
            case .created:
                return next == HandoffOverrideStatus.published
            case .validated:
                return next == HandoffOverrideStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: HandoffOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(capacity) - budget) * 100).rounded() / 100
        }

        func copyValue() -> HandoffOverride {
            return HandoffOverride(
                code: code,
                label: label,
                region: region,
                capacity: capacity,
                durationMinutes: durationMinutes,
                active: active,
                budget: budget,
                externalRef: externalRef,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a handoff override in status created.
    static func newHandoffOverride(_ code: String, label: String) -> HandoffOverride {
        return HandoffOverride(
            code: code,
            label: label,
            region: "",
            capacity: 0,
            durationMinutes: 0,
            active: false,
            budget: 0.0,
            externalRef: "",
            segment: "",
            status: HandoffOverrideStatus.created
        )
    }
}
