import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global worklist override is in its life cycle.
    enum GlobalWorklistOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a global worklist override and its current status.
    final class GlobalWorklistOverride {
        var code: String
        var label: String
        var dosageMg: Double
        var maximum: Double
        var windowDays: Int
        var retries: Int
        var timezone: String
        var checksum: String
        var createdAt: Int
        var status: GlobalWorklistOverrideStatus

        init(code: String, label: String, dosageMg: Double, maximum: Double, windowDays: Int, retries: Int, timezone: String, checksum: String, createdAt: Int, status: GlobalWorklistOverrideStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.maximum = maximum
            self.windowDays = windowDays
            self.retries = retries
            self.timezone = timezone
            self.checksum = checksum
            self.createdAt = createdAt
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

        func canMoveTo(_ next: GlobalWorklistOverrideStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GlobalWorklistOverrideStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: GlobalWorklistOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global worklist override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return (dosageMg * maximum * 100).rounded() / 100
        }

        func copyValue() -> GlobalWorklistOverride {
            return GlobalWorklistOverride(
                code: code,
                label: label,
                dosageMg: dosageMg,
                maximum: maximum,
                windowDays: windowDays,
                retries: retries,
                timezone: timezone,
                checksum: checksum,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global worklist override in status created.
    static func newGlobalWorklistOverride(_ code: String, label: String) -> GlobalWorklistOverride {
        return GlobalWorklistOverride(
            code: code,
            label: label,
            dosageMg: 0.0,
            maximum: 0.0,
            windowDays: 0,
            retries: 0,
            timezone: "",
            checksum: "",
            createdAt: 0,
            status: GlobalWorklistOverrideStatus.created
        )
    }
}
