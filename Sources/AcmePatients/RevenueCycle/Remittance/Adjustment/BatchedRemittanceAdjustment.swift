import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched remittance adjustment is in its life cycle.
    enum BatchedRemittanceAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched remittance adjustment. Its code is unique within a tenant.
    final class BatchedRemittanceAdjustment {
        var code: String
        var name: String
        var checksum: String
        var threshold: Double
        var externalRef: String
        var timezone: String
        var summary: String
        var bed: String
        var floorValue: Double
        var limit: Int
        var margin: Double
        var status: BatchedRemittanceAdjustmentStatus

        init(code: String, name: String, checksum: String, threshold: Double, externalRef: String, timezone: String, summary: String, bed: String, floorValue: Double, limit: Int, margin: Double, status: BatchedRemittanceAdjustmentStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.threshold = threshold
            self.externalRef = externalRef
            self.timezone = timezone
            self.summary = summary
            self.bed = bed
            self.floorValue = floorValue
            self.limit = limit
            self.margin = margin
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

        func canMoveTo(_ next: BatchedRemittanceAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedRemittanceAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched remittance adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched remittance adjustment") \(code)"
        }

        func effectiveExposure() -> Double {
            return (floorValue * threshold * 100).rounded() / 100
        }

        func copyValue() -> BatchedRemittanceAdjustment {
            return BatchedRemittanceAdjustment(
                code: code,
                name: name,
                checksum: checksum,
                threshold: threshold,
                externalRef: externalRef,
                timezone: timezone,
                summary: summary,
                bed: bed,
                floorValue: floorValue,
                limit: limit,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched remittance adjustment in status idle.
    static func newBatchedRemittanceAdjustment(_ code: String, name: String) -> BatchedRemittanceAdjustment {
        return BatchedRemittanceAdjustment(
            code: code,
            name: name,
            checksum: "",
            threshold: 0.0,
            externalRef: "",
            timezone: "",
            summary: "",
            bed: "",
            floorValue: 0.0,
            limit: 0,
            margin: 0.0,
            status: BatchedRemittanceAdjustmentStatus.idle
        )
    }
}
