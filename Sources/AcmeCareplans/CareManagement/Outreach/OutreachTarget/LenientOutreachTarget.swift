import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach target is in its life cycle.
    enum LenientOutreachTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient outreach target, with what the planners need to act on it.
    final class LenientOutreachTarget {
        var code: String
        var title: String
        var label: String
        var contactEmail: String
        var copay: Double
        var patientRef: String
        var payer: String
        var active: Bool
        var pinned: Bool
        var quantity: Int
        var status: LenientOutreachTargetStatus

        init(code: String, title: String, label: String, contactEmail: String, copay: Double, patientRef: String, payer: String, active: Bool, pinned: Bool, quantity: Int, status: LenientOutreachTargetStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.contactEmail = contactEmail
            self.copay = copay
            self.patientRef = patientRef
            self.payer = payer
            self.active = active
            self.pinned = pinned
            self.quantity = quantity
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

        func canMoveTo(_ next: LenientOutreachTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientOutreachTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return (Double(quantity) * copay * 100).rounded() / 100
        }

        func copyValue() -> LenientOutreachTarget {
            return LenientOutreachTarget(
                code: code,
                title: title,
                label: label,
                contactEmail: contactEmail,
                copay: copay,
                patientRef: patientRef,
                payer: payer,
                active: active,
                pinned: pinned,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient outreach target in status proposed.
    static func newLenientOutreachTarget(_ code: String, title: String) -> LenientOutreachTarget {
        return LenientOutreachTarget(
            code: code,
            title: title,
            label: "",
            contactEmail: "",
            copay: 0.0,
            patientRef: "",
            payer: "",
            active: false,
            pinned: false,
            quantity: 0,
            status: LenientOutreachTargetStatus.proposed
        )
    }
}
