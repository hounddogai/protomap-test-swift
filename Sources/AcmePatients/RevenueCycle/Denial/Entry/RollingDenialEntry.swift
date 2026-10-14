import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling denial entry is in its life cycle.
    enum RollingDenialEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling denial entry, with what the planners need to act on it.
    final class RollingDenialEntry {
        var code: String
        var label: String
        var maximum: Double
        var region: String
        var budget: Double
        var procedureCode: String
        var status: RollingDenialEntryStatus

        init(code: String, label: String, maximum: Double, region: String, budget: Double, procedureCode: String, status: RollingDenialEntryStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.region = region
            self.budget = budget
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RollingDenialEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingDenialEntryStatus.running || next == RollingDenialEntryStatus.done
            case .queued:
                return next == RollingDenialEntryStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingDenialEntryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingDenialEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling denial entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return (budget * maximum * 100).rounded() / 100
        }

        func copyValue() -> RollingDenialEntry {
            return RollingDenialEntry(
                code: code,
                label: label,
                maximum: maximum,
                region: region,
                budget: budget,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling denial entry in status new.
    static func newRollingDenialEntry(_ code: String, label: String) -> RollingDenialEntry {
        return RollingDenialEntry(
            code: code,
            label: label,
            maximum: 0.0,
            region: "",
            budget: 0.0,
            procedureCode: "",
            status: RollingDenialEntryStatus.new
        )
    }
}
