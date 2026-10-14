import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive result adjustment is in its life cycle.
    enum AdaptiveResultAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive result adjustment. Its code is unique within a tenant.
    final class AdaptiveResultAdjustment {
        var code: String
        var label: String
        var copay: Double
        var archived: Bool
        var sequence: Int
        var status: AdaptiveResultAdjustmentStatus

        init(code: String, label: String, copay: Double, archived: Bool, sequence: Int, status: AdaptiveResultAdjustmentStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.archived = archived
            self.sequence = sequence
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

        func canMoveTo(_ next: AdaptiveResultAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveResultAdjustmentStatus.queued || next == AdaptiveResultAdjustmentStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveResultAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive result adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((Double(sequence) + copay) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveResultAdjustment {
            return AdaptiveResultAdjustment(
                code: code,
                label: label,
                copay: copay,
                archived: archived,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive result adjustment in status new.
    static func newAdaptiveResultAdjustment(_ code: String, label: String) -> AdaptiveResultAdjustment {
        return AdaptiveResultAdjustment(
            code: code,
            label: label,
            copay: 0.0,
            archived: false,
            sequence: 0,
            status: AdaptiveResultAdjustmentStatus.new
        )
    }
}
