import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient follow up manifest is in its life cycle.
    enum LenientFollowUpManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient follow up manifest as the follow up team keeps it.
    final class LenientFollowUpManifest {
        var code: String
        var title: String
        var floorValue: Double
        var priority: Int
        var unit: String
        var timezone: String
        var checksum: String
        var graceDays: Int
        var batchSize: Int
        var description: String
        var status: LenientFollowUpManifestStatus

        init(code: String, title: String, floorValue: Double, priority: Int, unit: String, timezone: String, checksum: String, graceDays: Int, batchSize: Int, description: String, status: LenientFollowUpManifestStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.priority = priority
            self.unit = unit
            self.timezone = timezone
            self.checksum = checksum
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.description = description
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

        func canMoveTo(_ next: LenientFollowUpManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientFollowUpManifestStatus.inReview || next == LenientFollowUpManifestStatus.archived
            case .inReview:
                return next == LenientFollowUpManifestStatus.reopened
            case .resolved:
                return next == LenientFollowUpManifestStatus.reopened || next == LenientFollowUpManifestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LenientFollowUpManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient follow up manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((floorValue - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientFollowUpManifest {
            return LenientFollowUpManifest(
                code: code,
                title: title,
                floorValue: floorValue,
                priority: priority,
                unit: unit,
                timezone: timezone,
                checksum: checksum,
                graceDays: graceDays,
                batchSize: batchSize,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient follow up manifest in status open.
    static func newLenientFollowUpManifest(_ code: String, title: String) -> LenientFollowUpManifest {
        return LenientFollowUpManifest(
            code: code,
            title: title,
            floorValue: 0.0,
            priority: 0,
            unit: "",
            timezone: "",
            checksum: "",
            graceDays: 0,
            batchSize: 0,
            description: "",
            status: LenientFollowUpManifestStatus.`open`
        )
    }
}
