import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched cleaning request is in its life cycle.
    enum BatchedCleaningRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched cleaning request as the cleaning team keeps it.
    final class BatchedCleaningRequest {
        var code: String
        var name: String
        var summary: String
        var threshold: Double
        var maximum: Double
        var discount: Double
        var quantity: Int
        var phone: String
        var region: String
        var diagnosisCode: String
        var sequence: Int
        var status: BatchedCleaningRequestStatus

        init(code: String, name: String, summary: String, threshold: Double, maximum: Double, discount: Double, quantity: Int, phone: String, region: String, diagnosisCode: String, sequence: Int, status: BatchedCleaningRequestStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.threshold = threshold
            self.maximum = maximum
            self.discount = discount
            self.quantity = quantity
            self.phone = phone
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
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

        func canMoveTo(_ next: BatchedCleaningRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedCleaningRequestStatus.revoked || next == BatchedCleaningRequestStatus.expired
            case .granted:
                return next == BatchedCleaningRequestStatus.revoked
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

        func moveTo(_ next: BatchedCleaningRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched cleaning request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return ((maximum + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCleaningRequest {
            return BatchedCleaningRequest(
                code: code,
                name: name,
                summary: summary,
                threshold: threshold,
                maximum: maximum,
                discount: discount,
                quantity: quantity,
                phone: phone,
                region: region,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a batched cleaning request in status requested.
    static func newBatchedCleaningRequest(_ code: String, name: String) -> BatchedCleaningRequest {
        return BatchedCleaningRequest(
            code: code,
            name: name,
            summary: "",
            threshold: 0.0,
            maximum: 0.0,
            discount: 0.0,
            quantity: 0,
            phone: "",
            region: "",
            diagnosisCode: "",
            sequence: 0,
            status: BatchedCleaningRequestStatus.requested
        )
    }
}
