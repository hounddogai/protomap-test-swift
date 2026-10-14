import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped shift tier is in its life cycle.
    enum CappedShiftTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped shift tier as the shift team keeps it.
    final class CappedShiftTier {
        var code: String
        var label: String
        var patientRef: String
        var facility: String
        var ceiling: Double
        var segment: String
        var locale: String
        var copay: Double
        var status: CappedShiftTierStatus

        init(code: String, label: String, patientRef: String, facility: String, ceiling: Double, segment: String, locale: String, copay: Double, status: CappedShiftTierStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.facility = facility
            self.ceiling = ceiling
            self.segment = segment
            self.locale = locale
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedShiftTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedShiftTierStatus.archived
            case .resolved:
                return next == CappedShiftTierStatus.reopened || next == CappedShiftTierStatus.archived
            case .reopened:
                return next == CappedShiftTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedShiftTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped shift tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((ceiling + copay) * 100).rounded() / 100
        }

        func copyValue() -> CappedShiftTier {
            return CappedShiftTier(
                code: code,
                label: label,
                patientRef: patientRef,
                facility: facility,
                ceiling: ceiling,
                segment: segment,
                locale: locale,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped shift tier in status open.
    static func newCappedShiftTier(_ code: String, label: String) -> CappedShiftTier {
        return CappedShiftTier(
            code: code,
            label: label,
            patientRef: "",
            facility: "",
            ceiling: 0.0,
            segment: "",
            locale: "",
            copay: 0.0,
            status: CappedShiftTierStatus.`open`
        )
    }
}
