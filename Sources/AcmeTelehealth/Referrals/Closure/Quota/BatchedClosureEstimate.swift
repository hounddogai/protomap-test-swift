import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched closure estimate is in its life cycle.
    enum BatchedClosureEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched closure estimate as the closure team keeps it.
    final class BatchedClosureEstimate {
        var code: String
        var label: String
        var segment: String
        var refills: Int
        var externalRef: String
        var threshold: Double
        var quantity: Int
        var checksum: String
        var facility: String
        var specialty: String
        var visitMinutes: Int
        var status: BatchedClosureEstimateStatus

        init(code: String, label: String, segment: String, refills: Int, externalRef: String, threshold: Double, quantity: Int, checksum: String, facility: String, specialty: String, visitMinutes: Int, status: BatchedClosureEstimateStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.refills = refills
            self.externalRef = externalRef
            self.threshold = threshold
            self.quantity = quantity
            self.checksum = checksum
            self.facility = facility
            self.specialty = specialty
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: BatchedClosureEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedClosureEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedClosureEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched closure estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched closure estimate") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(refills) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> BatchedClosureEstimate {
            return BatchedClosureEstimate(
                code: code,
                label: label,
                segment: segment,
                refills: refills,
                externalRef: externalRef,
                threshold: threshold,
                quantity: quantity,
                checksum: checksum,
                facility: facility,
                specialty: specialty,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched closure estimate in status requested.
    static func newBatchedClosureEstimate(_ code: String, label: String) -> BatchedClosureEstimate {
        return BatchedClosureEstimate(
            code: code,
            label: label,
            segment: "",
            refills: 0,
            externalRef: "",
            threshold: 0.0,
            quantity: 0,
            checksum: "",
            facility: "",
            specialty: "",
            visitMinutes: 0,
            status: BatchedClosureEstimateStatus.requested
        )
    }
}
