import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall bundle is in its life cycle.
    enum RecallBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall bundle as the recall team keeps it.
    final class RecallBundle {
        var code: String
        var label: String
        var attempts: Int
        var unit: String
        var threshold: Double
        var status: RecallBundleStatus

        init(code: String, label: String, attempts: Int, unit: String, threshold: Double, status: RecallBundleStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.unit = unit
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RecallBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("recall bundle") \(code)"
        }

        func netVolume() -> Double {
            return (threshold * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RecallBundle {
            return RecallBundle(
                code: code,
                label: label,
                attempts: attempts,
                unit: unit,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a recall bundle in status open.
    static func newRecallBundle(_ code: String, label: String) -> RecallBundle {
        return RecallBundle(
            code: code,
            label: label,
            attempts: 0,
            unit: "",
            threshold: 0.0,
            status: RecallBundleStatus.`open`
        )
    }
}
