import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional proxy quota is in its life cycle.
    enum RegionalProxyQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional proxy quota and its current status.
    final class RegionalProxyQuota {
        var code: String
        var name: String
        var facility: String
        var copay: Double
        var source: String
        var unit: String
        var encounterID: String
        var startsAt: Int
        var status: RegionalProxyQuotaStatus

        init(code: String, name: String, facility: String, copay: Double, source: String, unit: String, encounterID: String, startsAt: Int, status: RegionalProxyQuotaStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.copay = copay
            self.source = source
            self.unit = unit
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalProxyQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalProxyQuotaStatus.completed || next == RegionalProxyQuotaStatus.cancelled
            case .scheduled:
                return next == RegionalProxyQuotaStatus.cancelled
            case .inProgress:
                return next == RegionalProxyQuotaStatus.completed || next == RegionalProxyQuotaStatus.cancelled
            case .completed:
                return next == RegionalProxyQuotaStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalProxyQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional proxy quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((copay + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalProxyQuota {
            return RegionalProxyQuota(
                code: code,
                name: name,
                facility: facility,
                copay: copay,
                source: source,
                unit: unit,
                encounterID: encounterID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional proxy quota in status planned.
    static func newRegionalProxyQuota(_ code: String, name: String) -> RegionalProxyQuota {
        return RegionalProxyQuota(
            code: code,
            name: name,
            facility: "",
            copay: 0.0,
            source: "",
            unit: "",
            encounterID: "",
            startsAt: 0,
            status: RegionalProxyQuotaStatus.planned
        )
    }
}
