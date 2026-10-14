import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy claim profile is in its life cycle.
    enum LegacyClaimProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy claim profile, with what the planners need to act on it.
    final class LegacyClaimProfile {
        var code: String
        var name: String
        var dosageMg: Double
        var summary: String
        var notes: String
        var status: LegacyClaimProfileStatus

        init(code: String, name: String, dosageMg: Double, summary: String, notes: String, status: LegacyClaimProfileStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.summary = summary
            self.notes = notes
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

        func canMoveTo(_ next: LegacyClaimProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LegacyClaimProfileStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LegacyClaimProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyClaimProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy claim profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> LegacyClaimProfile {
            return LegacyClaimProfile(
                code: code,
                name: name,
                dosageMg: dosageMg,
                summary: summary,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy claim profile in status new.
    static func newLegacyClaimProfile(_ code: String, name: String) -> LegacyClaimProfile {
        return LegacyClaimProfile(
            code: code,
            name: name,
            dosageMg: 0.0,
            summary: "",
            notes: "",
            status: LegacyClaimProfileStatus.new
        )
    }
}
