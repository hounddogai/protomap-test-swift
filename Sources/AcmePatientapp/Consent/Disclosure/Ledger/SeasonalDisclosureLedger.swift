import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal disclosure ledger is in its life cycle.
    enum SeasonalDisclosureLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal disclosure ledger and its current status.
    final class SeasonalDisclosureLedger {
        var code: String
        var label: String
        var approved: Bool
        var copay: Double
        var visible: Bool
        var rate: Double
        var expiresAt: Int
        var active: Bool
        var status: SeasonalDisclosureLedgerStatus

        init(code: String, label: String, approved: Bool, copay: Double, visible: Bool, rate: Double, expiresAt: Int, active: Bool, status: SeasonalDisclosureLedgerStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.copay = copay
            self.visible = visible
            self.rate = rate
            self.expiresAt = expiresAt
            self.active = active
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

        func canMoveTo(_ next: SeasonalDisclosureLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalDisclosureLedgerStatus.running
            case .queued:
                return next == SeasonalDisclosureLedgerStatus.running || next == SeasonalDisclosureLedgerStatus.done
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: SeasonalDisclosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal disclosure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return ((Double(expiresAt) + copay) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDisclosureLedger {
            return SeasonalDisclosureLedger(
                code: code,
                label: label,
                approved: approved,
                copay: copay,
                visible: visible,
                rate: rate,
                expiresAt: expiresAt,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal disclosure ledger in status new.
    static func newSeasonalDisclosureLedger(_ code: String, label: String) -> SeasonalDisclosureLedger {
        return SeasonalDisclosureLedger(
            code: code,
            label: label,
            approved: false,
            copay: 0.0,
            visible: false,
            rate: 0.0,
            expiresAt: 0,
            active: false,
            status: SeasonalDisclosureLedgerStatus.new
        )
    }
}
