import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched claim estimate is in its life cycle.
    enum BatchedClaimEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched claim estimate. Its code is unique within a tenant.
    final class BatchedClaimEstimate {
        var code: String
        var title: String
        var payer: String
        var copay: Double
        var externalRef: String
        var segment: String
        var category: String
        var allergy: String
        var status: BatchedClaimEstimateStatus

        init(code: String, title: String, payer: String, copay: Double, externalRef: String, segment: String, category: String, allergy: String, status: BatchedClaimEstimateStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.copay = copay
            self.externalRef = externalRef
            self.segment = segment
            self.category = category
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedClaimEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedClaimEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched claim estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> BatchedClaimEstimate {
            return BatchedClaimEstimate(
                code: code,
                title: title,
                payer: payer,
                copay: copay,
                externalRef: externalRef,
                segment: segment,
                category: category,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched claim estimate in status planned.
    static func newBatchedClaimEstimate(_ code: String, title: String) -> BatchedClaimEstimate {
        return BatchedClaimEstimate(
            code: code,
            title: title,
            payer: "",
            copay: 0.0,
            externalRef: "",
            segment: "",
            category: "",
            allergy: "",
            status: BatchedClaimEstimateStatus.planned
        )
    }
}
