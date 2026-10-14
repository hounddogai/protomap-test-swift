import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer profile is in its life cycle.
    enum TransferProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A transfer profile as the transfer team keeps it.
    final class TransferProfile {
        var code: String
        var label: String
        var specialty: String
        var approved: Bool
        var active: Bool
        var procedureCode: String
        var attempts: Int
        var floorValue: Double
        var discount: Double
        var contactEmail: String
        var status: TransferProfileStatus

        init(code: String, label: String, specialty: String, approved: Bool, active: Bool, procedureCode: String, attempts: Int, floorValue: Double, discount: Double, contactEmail: String, status: TransferProfileStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.approved = approved
            self.active = active
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.floorValue = floorValue
            self.discount = discount
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: TransferProfileStatus) -> Bool {
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
                return next == TransferProfileStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TransferProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((discount - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> TransferProfile {
            return TransferProfile(
                code: code,
                label: label,
                specialty: specialty,
                approved: approved,
                active: active,
                procedureCode: procedureCode,
                attempts: attempts,
                floorValue: floorValue,
                discount: discount,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer profile in status idle.
    static func newTransferProfile(_ code: String, label: String) -> TransferProfile {
        return TransferProfile(
            code: code,
            label: label,
            specialty: "",
            approved: false,
            active: false,
            procedureCode: "",
            attempts: 0,
            floorValue: 0.0,
            discount: 0.0,
            contactEmail: "",
            status: TransferProfileStatus.idle
        )
    }
}
