import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback float pool adjustment is in its life cycle.
    enum FallbackFloatPoolAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback float pool adjustment and its current status.
    final class FallbackFloatPoolAdjustment {
        var code: String
        var label: String
        var category: String
        var expiresAt: Int
        var version: Int
        var procedureCode: String
        var status: FallbackFloatPoolAdjustmentStatus

        init(code: String, label: String, category: String, expiresAt: Int, version: Int, procedureCode: String, status: FallbackFloatPoolAdjustmentStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.expiresAt = expiresAt
            self.version = version
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: FallbackFloatPoolAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackFloatPoolAdjustmentStatus.scheduled || next == FallbackFloatPoolAdjustmentStatus.completed
            case .scheduled:
                return next == FallbackFloatPoolAdjustmentStatus.cancelled
            case .inProgress:
                return next == FallbackFloatPoolAdjustmentStatus.completed || next == FallbackFloatPoolAdjustmentStatus.cancelled
            case .completed:
                return next == FallbackFloatPoolAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackFloatPoolAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback float pool adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("fallback float pool adjustment") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFloatPoolAdjustment {
            return FallbackFloatPoolAdjustment(
                code: code,
                label: label,
                category: category,
                expiresAt: expiresAt,
                version: version,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback float pool adjustment in status planned.
    static func newFallbackFloatPoolAdjustment(_ code: String, label: String) -> FallbackFloatPoolAdjustment {
        return FallbackFloatPoolAdjustment(
            code: code,
            label: label,
            category: "",
            expiresAt: 0,
            version: 0,
            procedureCode: "",
            status: FallbackFloatPoolAdjustmentStatus.planned
        )
    }
}
