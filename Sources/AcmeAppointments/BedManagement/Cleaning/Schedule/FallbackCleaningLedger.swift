import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback cleaning ledger is in its life cycle.
    enum FallbackCleaningLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback cleaning ledger. Its code is unique within a tenant.
    final class FallbackCleaningLedger {
        var code: String
        var label: String
        var facility: String
        var startsAt: Int
        var ceiling: Double
        var status: FallbackCleaningLedgerStatus

        init(code: String, label: String, facility: String, startsAt: Int, ceiling: Double, status: FallbackCleaningLedgerStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCleaningLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackCleaningLedgerStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackCleaningLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCleaningLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback cleaning ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCleaningLedger {
            return FallbackCleaningLedger(
                code: code,
                label: label,
                facility: facility,
                startsAt: startsAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback cleaning ledger in status requested.
    static func newFallbackCleaningLedger(_ code: String, label: String) -> FallbackCleaningLedger {
        return FallbackCleaningLedger(
            code: code,
            label: label,
            facility: "",
            startsAt: 0,
            ceiling: 0.0,
            status: FallbackCleaningLedgerStatus.requested
        )
    }
}
