import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending worklist estimate is in its life cycle.
    enum PendingWorklistEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending worklist estimate. Its code is unique within a tenant.
    final class PendingWorklistEstimate {
        var code: String
        var name: String
        var patientRef: String
        var visible: Bool
        var acuity: Int
        var timezone: String
        var windowDays: Int
        var cost: Double
        var active: Bool
        var externalRef: String
        var ward: String
        var status: PendingWorklistEstimateStatus

        init(code: String, name: String, patientRef: String, visible: Bool, acuity: Int, timezone: String, windowDays: Int, cost: Double, active: Bool, externalRef: String, ward: String, status: PendingWorklistEstimateStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.visible = visible
            self.acuity = acuity
            self.timezone = timezone
            self.windowDays = windowDays
            self.cost = cost
            self.active = active
            self.externalRef = externalRef
            self.ward = ward
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

        func canMoveTo(_ next: PendingWorklistEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingWorklistEstimateStatus.published || next == PendingWorklistEstimateStatus.retired
            case .validated:
                return next == PendingWorklistEstimateStatus.published
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

        func moveTo(_ next: PendingWorklistEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending worklist estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((Double(windowDays) - cost) * 100).rounded() / 100
        }

        func copyValue() -> PendingWorklistEstimate {
            return PendingWorklistEstimate(
                code: code,
                name: name,
                patientRef: patientRef,
                visible: visible,
                acuity: acuity,
                timezone: timezone,
                windowDays: windowDays,
                cost: cost,
                active: active,
                externalRef: externalRef,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending worklist estimate in status created.
    static func newPendingWorklistEstimate(_ code: String, name: String) -> PendingWorklistEstimate {
        return PendingWorklistEstimate(
            code: code,
            name: name,
            patientRef: "",
            visible: false,
            acuity: 0,
            timezone: "",
            windowDays: 0,
            cost: 0.0,
            active: false,
            externalRef: "",
            ward: "",
            status: PendingWorklistEstimateStatus.created
        )
    }
}
