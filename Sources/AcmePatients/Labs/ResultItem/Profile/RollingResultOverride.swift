import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result override is in its life cycle.
    enum RollingResultOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling result override as the result team keeps it.
    final class RollingResultOverride {
        var code: String
        var label: String
        var approved: Bool
        var refills: Int
        var durationMinutes: Int
        var pinned: Bool
        var score: Double
        var attributes: [String: String]
        var timezone: String
        var copay: Double
        var status: RollingResultOverrideStatus

        init(code: String, label: String, approved: Bool, refills: Int, durationMinutes: Int, pinned: Bool, score: Double, attributes: [String: String], timezone: String, copay: Double, status: RollingResultOverrideStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.score = score
            self.attributes = attributes
            self.timezone = timezone
            self.copay = copay
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

        func canMoveTo(_ next: RollingResultOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingResultOverrideStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingResultOverrideStatus.failed
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

        func moveTo(_ next: RollingResultOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func netLoad() -> Double {
            return (Double(refills) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RollingResultOverride {
            return RollingResultOverride(
                code: code,
                label: label,
                approved: approved,
                refills: refills,
                durationMinutes: durationMinutes,
                pinned: pinned,
                score: score,
                attributes: attributes,
                timezone: timezone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling result override in status new.
    static func newRollingResultOverride(_ code: String, label: String) -> RollingResultOverride {
        return RollingResultOverride(
            code: code,
            label: label,
            approved: false,
            refills: 0,
            durationMinutes: 0,
            pinned: false,
            score: 0.0,
            attributes: [:],
            timezone: "",
            copay: 0.0,
            status: RollingResultOverrideStatus.new
        )
    }
}
