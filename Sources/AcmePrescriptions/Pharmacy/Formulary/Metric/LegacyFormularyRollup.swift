import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy formulary rollup is in its life cycle.
    enum LegacyFormularyRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy formulary rollup as the formulary team keeps it.
    final class LegacyFormularyRollup {
        var code: String
        var label: String
        var ward: String
        var expiresAt: Int
        var attempts: Int
        var ceiling: Double
        var timezone: String
        var graceDays: Int
        var refills: Int
        var tags: [String]
        var pinned: Bool
        var status: LegacyFormularyRollupStatus

        init(code: String, label: String, ward: String, expiresAt: Int, attempts: Int, ceiling: Double, timezone: String, graceDays: Int, refills: Int, tags: [String], pinned: Bool, status: LegacyFormularyRollupStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.ceiling = ceiling
            self.timezone = timezone
            self.graceDays = graceDays
            self.refills = refills
            self.tags = tags
            self.pinned = pinned
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

        func canMoveTo(_ next: LegacyFormularyRollupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LegacyFormularyRollupStatus.running
            case .running:
                return next == LegacyFormularyRollupStatus.done || next == LegacyFormularyRollupStatus.failed
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

        func moveTo(_ next: LegacyFormularyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy formulary rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("legacy formulary rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(graceDays) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyFormularyRollup {
            return LegacyFormularyRollup(
                code: code,
                label: label,
                ward: ward,
                expiresAt: expiresAt,
                attempts: attempts,
                ceiling: ceiling,
                timezone: timezone,
                graceDays: graceDays,
                refills: refills,
                tags: tags,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy formulary rollup in status new.
    static func newLegacyFormularyRollup(_ code: String, label: String) -> LegacyFormularyRollup {
        return LegacyFormularyRollup(
            code: code,
            label: label,
            ward: "",
            expiresAt: 0,
            attempts: 0,
            ceiling: 0.0,
            timezone: "",
            graceDays: 0,
            refills: 0,
            tags: [],
            pinned: false,
            status: LegacyFormularyRollupStatus.new
        )
    }
}
