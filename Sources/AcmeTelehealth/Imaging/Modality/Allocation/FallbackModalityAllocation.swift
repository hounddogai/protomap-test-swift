import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback modality allocation is in its life cycle.
    enum FallbackModalityAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback modality allocation and its current status.
    final class FallbackModalityAllocation {
        var code: String
        var label: String
        var visitMinutes: Int
        var ceiling: Double
        var copay: Double
        var active: Bool
        var retries: Int
        var amount: Double
        var source: String
        var checksum: String
        var status: FallbackModalityAllocationStatus

        init(code: String, label: String, visitMinutes: Int, ceiling: Double, copay: Double, active: Bool, retries: Int, amount: Double, source: String, checksum: String, status: FallbackModalityAllocationStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.copay = copay
            self.active = active
            self.retries = retries
            self.amount = amount
            self.source = source
            self.checksum = checksum
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

        func canMoveTo(_ next: FallbackModalityAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackModalityAllocationStatus.inProgress || next == FallbackModalityAllocationStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FallbackModalityAllocationStatus.completed || next == FallbackModalityAllocationStatus.cancelled
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

        func moveTo(_ next: FallbackModalityAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback modality allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return ((copay - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackModalityAllocation {
            return FallbackModalityAllocation(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                copay: copay,
                active: active,
                retries: retries,
                amount: amount,
                source: source,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback modality allocation in status planned.
    static func newFallbackModalityAllocation(_ code: String, label: String) -> FallbackModalityAllocation {
        return FallbackModalityAllocation(
            code: code,
            label: label,
            visitMinutes: 0,
            ceiling: 0.0,
            copay: 0.0,
            active: false,
            retries: 0,
            amount: 0.0,
            source: "",
            checksum: "",
            status: FallbackModalityAllocationStatus.planned
        )
    }
}
