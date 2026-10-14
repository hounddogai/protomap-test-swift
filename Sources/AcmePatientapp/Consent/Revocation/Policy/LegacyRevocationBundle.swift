import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy revocation bundle is in its life cycle.
    enum LegacyRevocationBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy revocation bundle. Its code is unique within a tenant.
    final class LegacyRevocationBundle {
        var code: String
        var title: String
        var ownerID: String
        var discount: Double
        var attributes: [String: String]
        var durationMinutes: Int
        var bed: String
        var status: LegacyRevocationBundleStatus

        init(code: String, title: String, ownerID: String, discount: Double, attributes: [String: String], durationMinutes: Int, bed: String, status: LegacyRevocationBundleStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.discount = discount
            self.attributes = attributes
            self.durationMinutes = durationMinutes
            self.bed = bed
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

        func canMoveTo(_ next: LegacyRevocationBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyRevocationBundleStatus.inProgress
            case .scheduled:
                return next == LegacyRevocationBundleStatus.completed
            case .inProgress:
                return next == LegacyRevocationBundleStatus.completed || next == LegacyRevocationBundleStatus.cancelled
            case .completed:
                return next == LegacyRevocationBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy revocation bundle") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return ((discount + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRevocationBundle {
            return LegacyRevocationBundle(
                code: code,
                title: title,
                ownerID: ownerID,
                discount: discount,
                attributes: attributes,
                durationMinutes: durationMinutes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy revocation bundle in status planned.
    static func newLegacyRevocationBundle(_ code: String, title: String) -> LegacyRevocationBundle {
        return LegacyRevocationBundle(
            code: code,
            title: title,
            ownerID: "",
            discount: 0.0,
            attributes: [:],
            durationMinutes: 0,
            bed: "",
            status: LegacyRevocationBundleStatus.planned
        )
    }
}
