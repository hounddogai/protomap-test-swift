import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy discharge plan digest is in its life cycle.
    enum LegacyDischargePlanDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a legacy discharge plan digest and its current status.
    final class LegacyDischargePlanDigest {
        var code: String
        var label: String
        var priority: Int
        var createdAt: Int
        var graceDays: Int
        var version: Int
        var status: LegacyDischargePlanDigestStatus

        init(code: String, label: String, priority: Int, createdAt: Int, graceDays: Int, version: Int, status: LegacyDischargePlanDigestStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.version = version
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

        func canMoveTo(_ next: LegacyDischargePlanDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyDischargePlanDigestStatus.queued || next == LegacyDischargePlanDigestStatus.done
            case .queued:
                return next == LegacyDischargePlanDigestStatus.done || next == LegacyDischargePlanDigestStatus.failed
            case .running:
                return next == LegacyDischargePlanDigestStatus.done
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

        func moveTo(_ next: LegacyDischargePlanDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy discharge plan digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return (Double(graceDays) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDischargePlanDigest {
            return LegacyDischargePlanDigest(
                code: code,
                label: label,
                priority: priority,
                createdAt: createdAt,
                graceDays: graceDays,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy discharge plan digest in status new.
    static func newLegacyDischargePlanDigest(_ code: String, label: String) -> LegacyDischargePlanDigest {
        return LegacyDischargePlanDigest(
            code: code,
            label: label,
            priority: 0,
            createdAt: 0,
            graceDays: 0,
            version: 0,
            status: LegacyDischargePlanDigestStatus.new
        )
    }
}
