import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality request is in its life cycle.
    enum CappedModalityRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped modality request. Its code is unique within a tenant.
    final class CappedModalityRequest {
        var code: String
        var label: String
        var bed: String
        var description: String
        var rate: Double
        var clinicianID: String
        var margin: Double
        var quantity: Int
        var floorValue: Double
        var status: CappedModalityRequestStatus

        init(code: String, label: String, bed: String, description: String, rate: Double, clinicianID: String, margin: Double, quantity: Int, floorValue: Double, status: CappedModalityRequestStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.description = description
            self.rate = rate
            self.clinicianID = clinicianID
            self.margin = margin
            self.quantity = quantity
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CappedModalityRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedModalityRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return (margin * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityRequest {
            return CappedModalityRequest(
                code: code,
                label: label,
                bed: bed,
                description: description,
                rate: rate,
                clinicianID: clinicianID,
                margin: margin,
                quantity: quantity,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped modality request in status created.
    static func newCappedModalityRequest(_ code: String, label: String) -> CappedModalityRequest {
        return CappedModalityRequest(
            code: code,
            label: label,
            bed: "",
            description: "",
            rate: 0.0,
            clinicianID: "",
            margin: 0.0,
            quantity: 0,
            floorValue: 0.0,
            status: CappedModalityRequestStatus.created
        )
    }
}
