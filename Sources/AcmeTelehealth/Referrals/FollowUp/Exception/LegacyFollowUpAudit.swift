import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy follow up audit is in its life cycle.
    enum LegacyFollowUpAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy follow up audit. Its code is unique within a tenant.
    final class LegacyFollowUpAudit {
        var code: String
        var label: String
        var weight: Double
        var maximum: Double
        var revision: Int
        var refills: Int
        var timezone: String
        var batchSize: Int
        var status: LegacyFollowUpAuditStatus

        init(code: String, label: String, weight: Double, maximum: Double, revision: Int, refills: Int, timezone: String, batchSize: Int, status: LegacyFollowUpAuditStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.maximum = maximum
            self.revision = revision
            self.refills = refills
            self.timezone = timezone
            self.batchSize = batchSize
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

        func canMoveTo(_ next: LegacyFollowUpAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LegacyFollowUpAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyFollowUpAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy follow up audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return (Double(refills) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> LegacyFollowUpAudit {
            return LegacyFollowUpAudit(
                code: code,
                label: label,
                weight: weight,
                maximum: maximum,
                revision: revision,
                refills: refills,
                timezone: timezone,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy follow up audit in status created.
    static func newLegacyFollowUpAudit(_ code: String, label: String) -> LegacyFollowUpAudit {
        return LegacyFollowUpAudit(
            code: code,
            label: label,
            weight: 0.0,
            maximum: 0.0,
            revision: 0,
            refills: 0,
            timezone: "",
            batchSize: 0,
            status: LegacyFollowUpAuditStatus.created
        )
    }
}
