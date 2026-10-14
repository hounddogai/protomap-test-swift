import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding audit is in its life cycle.
    enum RoundingAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rounding audit, with what the planners need to act on it.
    final class RoundingAudit {
        var code: String
        var name: String
        var encounterID: String
        var durationMinutes: Int
        var graceDays: Int
        var active: Bool
        var summary: String
        var ceiling: Double
        var status: RoundingAuditStatus

        init(code: String, name: String, encounterID: String, durationMinutes: Int, graceDays: Int, active: Bool, summary: String, ceiling: Double, status: RoundingAuditStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.durationMinutes = durationMinutes
            self.graceDays = graceDays
            self.active = active
            self.summary = summary
            self.ceiling = ceiling
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

        func canMoveTo(_ next: RoundingAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: RoundingAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return (Double(durationMinutes) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RoundingAudit {
            return RoundingAudit(
                code: code,
                name: name,
                encounterID: encounterID,
                durationMinutes: durationMinutes,
                graceDays: graceDays,
                active: active,
                summary: summary,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding audit in status new.
    static func newRoundingAudit(_ code: String, name: String) -> RoundingAudit {
        return RoundingAudit(
            code: code,
            name: name,
            encounterID: "",
            durationMinutes: 0,
            graceDays: 0,
            active: false,
            summary: "",
            ceiling: 0.0,
            status: RoundingAuditStatus.new
        )
    }
}
