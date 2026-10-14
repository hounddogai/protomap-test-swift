import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan bundle is in its life cycle.
    enum DischargePlanBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A discharge plan bundle. Its code is unique within a tenant.
    final class DischargePlanBundle {
        var code: String
        var label: String
        var externalRef: String
        var copay: Double
        var description: String
        var visible: Bool
        var priority: Int
        var region: String
        var cost: Double
        var weight: Double
        var specialty: String
        var status: DischargePlanBundleStatus

        init(code: String, label: String, externalRef: String, copay: Double, description: String, visible: Bool, priority: Int, region: String, cost: Double, weight: Double, specialty: String, status: DischargePlanBundleStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.copay = copay
            self.description = description
            self.visible = visible
            self.priority = priority
            self.region = region
            self.cost = cost
            self.weight = weight
            self.specialty = specialty
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

        func canMoveTo(_ next: DischargePlanBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == DischargePlanBundleStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DischargePlanBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return (weight * cost * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanBundle {
            return DischargePlanBundle(
                code: code,
                label: label,
                externalRef: externalRef,
                copay: copay,
                description: description,
                visible: visible,
                priority: priority,
                region: region,
                cost: cost,
                weight: weight,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a discharge plan bundle in status draft.
    static func newDischargePlanBundle(_ code: String, label: String) -> DischargePlanBundle {
        return DischargePlanBundle(
            code: code,
            label: label,
            externalRef: "",
            copay: 0.0,
            description: "",
            visible: false,
            priority: 0,
            region: "",
            cost: 0.0,
            weight: 0.0,
            specialty: "",
            status: DischargePlanBundleStatus.draft
        )
    }
}
