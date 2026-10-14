import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling remittance entry is in its life cycle.
    enum RollingRemittanceEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling remittance entry and its current status.
    final class RollingRemittanceEntry {
        var code: String
        var name: String
        var floorValue: Double
        var category: String
        var pinned: Bool
        var status: RollingRemittanceEntryStatus

        init(code: String, name: String, floorValue: Double, category: String, pinned: Bool, status: RollingRemittanceEntryStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.category = category
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

        func canMoveTo(_ next: RollingRemittanceEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingRemittanceEntryStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingRemittanceEntryStatus.failed
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

        func moveTo(_ next: RollingRemittanceEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling remittance entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling remittance entry") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> RollingRemittanceEntry {
            return RollingRemittanceEntry(
                code: code,
                name: name,
                floorValue: floorValue,
                category: category,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling remittance entry in status new.
    static func newRollingRemittanceEntry(_ code: String, name: String) -> RollingRemittanceEntry {
        return RollingRemittanceEntry(
            code: code,
            name: name,
            floorValue: 0.0,
            category: "",
            pinned: false,
            status: RollingRemittanceEntryStatus.new
        )
    }
}
