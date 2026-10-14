import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict formulary score is in its life cycle.
    enum StrictFormularyScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a strict formulary score and its current status.
    final class StrictFormularyScore {
        var code: String
        var label: String
        var contactEmail: String
        var encounterID: String
        var checksum: String
        var ownerID: String
        var quantity: Int
        var status: StrictFormularyScoreStatus

        init(code: String, label: String, contactEmail: String, encounterID: String, checksum: String, ownerID: String, quantity: Int, status: StrictFormularyScoreStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.encounterID = encounterID
            self.checksum = checksum
            self.ownerID = ownerID
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictFormularyScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictFormularyScoreStatus.revoked || next == StrictFormularyScoreStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: StrictFormularyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict formulary score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> StrictFormularyScore {
            return StrictFormularyScore(
                code: code,
                label: label,
                contactEmail: contactEmail,
                encounterID: encounterID,
                checksum: checksum,
                ownerID: ownerID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict formulary score in status requested.
    static func newStrictFormularyScore(_ code: String, label: String) -> StrictFormularyScore {
        return StrictFormularyScore(
            code: code,
            label: label,
            contactEmail: "",
            encounterID: "",
            checksum: "",
            ownerID: "",
            quantity: 0,
            status: StrictFormularyScoreStatus.requested
        )
    }
}
