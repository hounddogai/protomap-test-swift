import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered isolation template is in its life cycle.
    enum TieredIsolationTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered isolation template as the isolation team keeps it.
    final class TieredIsolationTemplate {
        var code: String
        var label: String
        var maximum: Double
        var threshold: Double
        var revision: Int
        var status: TieredIsolationTemplateStatus

        init(code: String, label: String, maximum: Double, threshold: Double, revision: Int, status: TieredIsolationTemplateStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.threshold = threshold
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredIsolationTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredIsolationTemplateStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: TieredIsolationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered isolation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((Double(revision) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> TieredIsolationTemplate {
            return TieredIsolationTemplate(
                code: code,
                label: label,
                maximum: maximum,
                threshold: threshold,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered isolation template in status proposed.
    static func newTieredIsolationTemplate(_ code: String, label: String) -> TieredIsolationTemplate {
        return TieredIsolationTemplate(
            code: code,
            label: label,
            maximum: 0.0,
            threshold: 0.0,
            revision: 0,
            status: TieredIsolationTemplateStatus.proposed
        )
    }
}
