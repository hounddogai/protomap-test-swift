import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional statement baseline is in its life cycle.
    enum RegionalStatementBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional statement baseline as the statement team keeps it.
    final class RegionalStatementBaseline {
        var code: String
        var label: String
        var encounterID: String
        var active: Bool
        var copay: Double
        var ward: String
        var status: RegionalStatementBaselineStatus

        init(code: String, label: String, encounterID: String, active: Bool, copay: Double, ward: String, status: RegionalStatementBaselineStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.active = active
            self.copay = copay
            self.ward = ward
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

        func canMoveTo(_ next: RegionalStatementBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RegionalStatementBaselineStatus.running || next == RegionalStatementBaselineStatus.done
            case .running:
                return next == RegionalStatementBaselineStatus.done
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

        func moveTo(_ next: RegionalStatementBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional statement baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> RegionalStatementBaseline {
            return RegionalStatementBaseline(
                code: code,
                label: label,
                encounterID: encounterID,
                active: active,
                copay: copay,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional statement baseline in status new.
    static func newRegionalStatementBaseline(_ code: String, label: String) -> RegionalStatementBaseline {
        return RegionalStatementBaseline(
            code: code,
            label: label,
            encounterID: "",
            active: false,
            copay: 0.0,
            ward: "",
            status: RegionalStatementBaselineStatus.new
        )
    }
}
