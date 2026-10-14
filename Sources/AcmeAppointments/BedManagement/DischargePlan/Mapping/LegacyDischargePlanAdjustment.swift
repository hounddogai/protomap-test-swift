import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy discharge plan adjustment is in its life cycle.
    enum LegacyDischargePlanAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy discharge plan adjustment, with what the planners need to act on it.
    final class LegacyDischargePlanAdjustment {
        var code: String
        var label: String
        var graceDays: Int
        var expiresAt: Int
        var acuity: Int
        var archived: Bool
        var floorValue: Double
        var version: Int
        var dosageMg: Double
        var tags: [String]
        var status: LegacyDischargePlanAdjustmentStatus

        init(code: String, label: String, graceDays: Int, expiresAt: Int, acuity: Int, archived: Bool, floorValue: Double, version: Int, dosageMg: Double, tags: [String], status: LegacyDischargePlanAdjustmentStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.archived = archived
            self.floorValue = floorValue
            self.version = version
            self.dosageMg = dosageMg
            self.tags = tags
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

        func canMoveTo(_ next: LegacyDischargePlanAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyDischargePlanAdjustmentStatus.running
            case .queued:
                return next == LegacyDischargePlanAdjustmentStatus.running
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: LegacyDischargePlanAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy discharge plan adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("legacy discharge plan adjustment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (floorValue * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDischargePlanAdjustment {
            return LegacyDischargePlanAdjustment(
                code: code,
                label: label,
                graceDays: graceDays,
                expiresAt: expiresAt,
                acuity: acuity,
                archived: archived,
                floorValue: floorValue,
                version: version,
                dosageMg: dosageMg,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy discharge plan adjustment in status new.
    static func newLegacyDischargePlanAdjustment(_ code: String, label: String) -> LegacyDischargePlanAdjustment {
        return LegacyDischargePlanAdjustment(
            code: code,
            label: label,
            graceDays: 0,
            expiresAt: 0,
            acuity: 0,
            archived: false,
            floorValue: 0.0,
            version: 0,
            dosageMg: 0.0,
            tags: [],
            status: LegacyDischargePlanAdjustmentStatus.new
        )
    }
}
