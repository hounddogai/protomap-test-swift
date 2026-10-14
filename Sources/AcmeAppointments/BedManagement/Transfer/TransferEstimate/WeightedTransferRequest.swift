import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer request is in its life cycle.
    enum WeightedTransferRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted transfer request and its current status.
    final class WeightedTransferRequest {
        var code: String
        var label: String
        var clinicianID: String
        var floorValue: Double
        var description: String
        var priority: Int
        var payer: String
        var locale: String
        var status: WeightedTransferRequestStatus

        init(code: String, label: String, clinicianID: String, floorValue: Double, description: String, priority: Int, payer: String, locale: String, status: WeightedTransferRequestStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.description = description
            self.priority = priority
            self.payer = payer
            self.locale = locale
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

        func canMoveTo(_ next: WeightedTransferRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedTransferRequestStatus.revoked || next == WeightedTransferRequestStatus.expired
            case .granted:
                return next == WeightedTransferRequestStatus.revoked || next == WeightedTransferRequestStatus.expired
            case .revoked:
                return next == WeightedTransferRequestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTransferRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return (Double(priority) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> WeightedTransferRequest {
            return WeightedTransferRequest(
                code: code,
                label: label,
                clinicianID: clinicianID,
                floorValue: floorValue,
                description: description,
                priority: priority,
                payer: payer,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted transfer request in status requested.
    static func newWeightedTransferRequest(_ code: String, label: String) -> WeightedTransferRequest {
        return WeightedTransferRequest(
            code: code,
            label: label,
            clinicianID: "",
            floorValue: 0.0,
            description: "",
            priority: 0,
            payer: "",
            locale: "",
            status: WeightedTransferRequestStatus.requested
        )
    }
}
