import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict eligibility entry is in its life cycle.
    enum StrictEligibilityEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict eligibility entry, with what the planners need to act on it.
    final class StrictEligibilityEntry {
        var code: String
        var title: String
        var ratio: Double
        var unit: String
        var summary: String
        var status: StrictEligibilityEntryStatus

        init(code: String, title: String, ratio: Double, unit: String, summary: String, status: StrictEligibilityEntryStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.unit = unit
            self.summary = summary
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

        func canMoveTo(_ next: StrictEligibilityEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictEligibilityEntryStatus.done || next == StrictEligibilityEntryStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictEligibilityEntryStatus.done
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

        func moveTo(_ next: StrictEligibilityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict eligibility entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict eligibility entry") \(code)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> StrictEligibilityEntry {
            return StrictEligibilityEntry(
                code: code,
                title: title,
                ratio: ratio,
                unit: unit,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict eligibility entry in status new.
    static func newStrictEligibilityEntry(_ code: String, title: String) -> StrictEligibilityEntry {
        return StrictEligibilityEntry(
            code: code,
            title: title,
            ratio: 0.0,
            unit: "",
            summary: "",
            status: StrictEligibilityEntryStatus.new
        )
    }
}
