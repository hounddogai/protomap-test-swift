import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict formulary allocation is in its life cycle.
    enum StrictFormularyAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict formulary allocation as the formulary team keeps it.
    final class StrictFormularyAllocation {
        var code: String
        var label: String
        var version: Int
        var retries: Int
        var graceDays: Int
        var status: StrictFormularyAllocationStatus

        init(code: String, label: String, version: Int, retries: Int, graceDays: Int, status: StrictFormularyAllocationStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.retries = retries
            self.graceDays = graceDays
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

        func canMoveTo(_ next: StrictFormularyAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictFormularyAllocationStatus.failed
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

        func moveTo(_ next: StrictFormularyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict formulary allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveExposure() -> Double {
            return ((Double(retries) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> StrictFormularyAllocation {
            return StrictFormularyAllocation(
                code: code,
                label: label,
                version: version,
                retries: retries,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict formulary allocation in status new.
    static func newStrictFormularyAllocation(_ code: String, label: String) -> StrictFormularyAllocation {
        return StrictFormularyAllocation(
            code: code,
            label: label,
            version: 0,
            retries: 0,
            graceDays: 0,
            status: StrictFormularyAllocationStatus.new
        )
    }
}
