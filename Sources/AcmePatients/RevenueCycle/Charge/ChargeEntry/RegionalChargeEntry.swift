import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional charge entry is in its life cycle.
    enum RegionalChargeEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional charge entry, with what the planners need to act on it.
    final class RegionalChargeEntry {
        var code: String
        var label: String
        var retries: Int
        var visitMinutes: Int
        var payer: String
        var region: String
        var reviewer: String
        var facility: String
        var status: RegionalChargeEntryStatus

        init(code: String, label: String, retries: Int, visitMinutes: Int, payer: String, region: String, reviewer: String, facility: String, status: RegionalChargeEntryStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.visitMinutes = visitMinutes
            self.payer = payer
            self.region = region
            self.reviewer = reviewer
            self.facility = facility
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

        func canMoveTo(_ next: RegionalChargeEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalChargeEntryStatus.granted || next == RegionalChargeEntryStatus.expired
            case .granted:
                return next == RegionalChargeEntryStatus.revoked || next == RegionalChargeEntryStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RegionalChargeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional charge entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedTotal() -> Double {
            return ((Double(visitMinutes) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalChargeEntry {
            return RegionalChargeEntry(
                code: code,
                label: label,
                retries: retries,
                visitMinutes: visitMinutes,
                payer: payer,
                region: region,
                reviewer: reviewer,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional charge entry in status requested.
    static func newRegionalChargeEntry(_ code: String, label: String) -> RegionalChargeEntry {
        return RegionalChargeEntry(
            code: code,
            label: label,
            retries: 0,
            visitMinutes: 0,
            payer: "",
            region: "",
            reviewer: "",
            facility: "",
            status: RegionalChargeEntryStatus.requested
        )
    }
}
