import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive acuity plan window is in its life cycle.
    enum AdaptiveAcuityPlanWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive acuity plan window. Its code is unique within a tenant.
    final class AdaptiveAcuityPlanWindow {
        var code: String
        var label: String
        var ward: String
        var durationMinutes: Int
        var checksum: String
        var tags: [String]
        var status: AdaptiveAcuityPlanWindowStatus

        init(code: String, label: String, ward: String, durationMinutes: Int, checksum: String, tags: [String], status: AdaptiveAcuityPlanWindowStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.checksum = checksum
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveAcuityPlanWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveAcuityPlanWindowStatus.approved || next == AdaptiveAcuityPlanWindowStatus.withdrawn
            case .approved:
                return next == AdaptiveAcuityPlanWindowStatus.rejected || next == AdaptiveAcuityPlanWindowStatus.withdrawn
            case .rejected:
                return next == AdaptiveAcuityPlanWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAcuityPlanWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive acuity plan window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> AdaptiveAcuityPlanWindow {
            return AdaptiveAcuityPlanWindow(
                code: code,
                label: label,
                ward: ward,
                durationMinutes: durationMinutes,
                checksum: checksum,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive acuity plan window in status proposed.
    static func newAdaptiveAcuityPlanWindow(_ code: String, label: String) -> AdaptiveAcuityPlanWindow {
        return AdaptiveAcuityPlanWindow(
            code: code,
            label: label,
            ward: "",
            durationMinutes: 0,
            checksum: "",
            tags: [],
            status: AdaptiveAcuityPlanWindowStatus.proposed
        )
    }
}
