import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched claim target is in its life cycle.
    enum BatchedClaimTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched claim target as the claim team keeps it.
    final class BatchedClaimTarget {
        var code: String
        var label: String
        var locale: String
        var ceiling: Double
        var checksum: String
        var externalRef: String
        var threshold: Double
        var reviewer: String
        var archived: Bool
        var amount: Double
        var ratio: Double
        var status: BatchedClaimTargetStatus

        init(code: String, label: String, locale: String, ceiling: Double, checksum: String, externalRef: String, threshold: Double, reviewer: String, archived: Bool, amount: Double, ratio: Double, status: BatchedClaimTargetStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.ceiling = ceiling
            self.checksum = checksum
            self.externalRef = externalRef
            self.threshold = threshold
            self.reviewer = reviewer
            self.archived = archived
            self.amount = amount
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedClaimTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedClaimTargetStatus.running || next == BatchedClaimTargetStatus.done
            case .running:
                return next == BatchedClaimTargetStatus.done || next == BatchedClaimTargetStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: BatchedClaimTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched claim target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched claim target") \(code)"
        }

        func effectiveValue() -> Double {
            return (ceiling * amount * 100).rounded() / 100
        }

        func copyValue() -> BatchedClaimTarget {
            return BatchedClaimTarget(
                code: code,
                label: label,
                locale: locale,
                ceiling: ceiling,
                checksum: checksum,
                externalRef: externalRef,
                threshold: threshold,
                reviewer: reviewer,
                archived: archived,
                amount: amount,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched claim target in status new.
    static func newBatchedClaimTarget(_ code: String, label: String) -> BatchedClaimTarget {
        return BatchedClaimTarget(
            code: code,
            label: label,
            locale: "",
            ceiling: 0.0,
            checksum: "",
            externalRef: "",
            threshold: 0.0,
            reviewer: "",
            archived: false,
            amount: 0.0,
            ratio: 0.0,
            status: BatchedClaimTargetStatus.new
        )
    }
}
