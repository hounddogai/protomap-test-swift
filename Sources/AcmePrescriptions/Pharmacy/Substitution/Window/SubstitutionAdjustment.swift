import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution adjustment is in its life cycle.
    enum SubstitutionAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A substitution adjustment as the substitution team keeps it.
    final class SubstitutionAdjustment {
        var code: String
        var label: String
        var contactEmail: String
        var title: String
        var score: Double
        var maximum: Double
        var floorValue: Double
        var payer: String
        var facility: String
        var visible: Bool
        var status: SubstitutionAdjustmentStatus

        init(code: String, label: String, contactEmail: String, title: String, score: Double, maximum: Double, floorValue: Double, payer: String, facility: String, visible: Bool, status: SubstitutionAdjustmentStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.title = title
            self.score = score
            self.maximum = maximum
            self.floorValue = floorValue
            self.payer = payer
            self.facility = facility
            self.visible = visible
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

        func canMoveTo(_ next: SubstitutionAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SubstitutionAdjustmentStatus.active || next == SubstitutionAdjustmentStatus.suspended
            case .active:
                return next == SubstitutionAdjustmentStatus.suspended
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

        func moveTo(_ next: SubstitutionAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return (maximum * floorValue * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionAdjustment {
            return SubstitutionAdjustment(
                code: code,
                label: label,
                contactEmail: contactEmail,
                title: title,
                score: score,
                maximum: maximum,
                floorValue: floorValue,
                payer: payer,
                facility: facility,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a substitution adjustment in status draft.
    static func newSubstitutionAdjustment(_ code: String, label: String) -> SubstitutionAdjustment {
        return SubstitutionAdjustment(
            code: code,
            label: label,
            contactEmail: "",
            title: "",
            score: 0.0,
            maximum: 0.0,
            floorValue: 0.0,
            payer: "",
            facility: "",
            visible: false,
            status: SubstitutionAdjustmentStatus.draft
        )
    }
}
