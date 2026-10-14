import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback discharge plan metric is in its life cycle.
    enum FallbackDischargePlanMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback discharge plan metric as the discharge plan team keeps it.
    final class FallbackDischargePlanMetric {
        var code: String
        var label: String
        var dosageMg: Double
        var pinned: Bool
        var facility: String
        var clinicianID: String
        var locale: String
        var visible: Bool
        var specialty: String
        var archived: Bool
        var attempts: Int
        var status: FallbackDischargePlanMetricStatus

        init(code: String, label: String, dosageMg: Double, pinned: Bool, facility: String, clinicianID: String, locale: String, visible: Bool, specialty: String, archived: Bool, attempts: Int, status: FallbackDischargePlanMetricStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.pinned = pinned
            self.facility = facility
            self.clinicianID = clinicianID
            self.locale = locale
            self.visible = visible
            self.specialty = specialty
            self.archived = archived
            self.attempts = attempts
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

        func canMoveTo(_ next: FallbackDischargePlanMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackDischargePlanMetricStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackDischargePlanMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDischargePlanMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback discharge plan metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return (Double(attempts) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> FallbackDischargePlanMetric {
            return FallbackDischargePlanMetric(
                code: code,
                label: label,
                dosageMg: dosageMg,
                pinned: pinned,
                facility: facility,
                clinicianID: clinicianID,
                locale: locale,
                visible: visible,
                specialty: specialty,
                archived: archived,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback discharge plan metric in status proposed.
    static func newFallbackDischargePlanMetric(_ code: String, label: String) -> FallbackDischargePlanMetric {
        return FallbackDischargePlanMetric(
            code: code,
            label: label,
            dosageMg: 0.0,
            pinned: false,
            facility: "",
            clinicianID: "",
            locale: "",
            visible: false,
            specialty: "",
            archived: false,
            attempts: 0,
            status: FallbackDischargePlanMetricStatus.proposed
        )
    }
}
