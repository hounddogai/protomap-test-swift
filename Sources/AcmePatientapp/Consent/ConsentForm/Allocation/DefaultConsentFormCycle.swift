import AcmePlatform
import Foundation

extension Consent {
    /// Where a default consent form cycle is in its life cycle.
    enum DefaultConsentFormCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default consent form cycle and its current status.
    final class DefaultConsentFormCycle {
        var code: String
        var title: String
        var ward: String
        var copay: Double
        var patientRef: String
        var dosageMg: Double
        var pinned: Bool
        var quantity: Int
        var channel: String
        var status: DefaultConsentFormCycleStatus

        init(code: String, title: String, ward: String, copay: Double, patientRef: String, dosageMg: Double, pinned: Bool, quantity: Int, channel: String, status: DefaultConsentFormCycleStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.copay = copay
            self.patientRef = patientRef
            self.dosageMg = dosageMg
            self.pinned = pinned
            self.quantity = quantity
            self.channel = channel
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

        func canMoveTo(_ next: DefaultConsentFormCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultConsentFormCycleStatus.resolved
            case .inReview:
                return next == DefaultConsentFormCycleStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DefaultConsentFormCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultConsentFormCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default consent form cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((Double(quantity) - copay) * 100).rounded() / 100
        }

        func copyValue() -> DefaultConsentFormCycle {
            return DefaultConsentFormCycle(
                code: code,
                title: title,
                ward: ward,
                copay: copay,
                patientRef: patientRef,
                dosageMg: dosageMg,
                pinned: pinned,
                quantity: quantity,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default consent form cycle in status open.
    static func newDefaultConsentFormCycle(_ code: String, title: String) -> DefaultConsentFormCycle {
        return DefaultConsentFormCycle(
            code: code,
            title: title,
            ward: "",
            copay: 0.0,
            patientRef: "",
            dosageMg: 0.0,
            pinned: false,
            quantity: 0,
            channel: "",
            status: DefaultConsentFormCycleStatus.`open`
        )
    }
}
