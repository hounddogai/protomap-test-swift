import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered care protocol allocation is in its life cycle.
    enum TieredCareProtocolAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered care protocol allocation. Its code is unique within a tenant.
    final class TieredCareProtocolAllocation {
        var code: String
        var title: String
        var unit: String
        var reviewer: String
        var summary: String
        var endsAt: Int
        var rate: Double
        var refills: Int
        var procedureCode: String
        var status: TieredCareProtocolAllocationStatus

        init(code: String, title: String, unit: String, reviewer: String, summary: String, endsAt: Int, rate: Double, refills: Int, procedureCode: String, status: TieredCareProtocolAllocationStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.reviewer = reviewer
            self.summary = summary
            self.endsAt = endsAt
            self.rate = rate
            self.refills = refills
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: TieredCareProtocolAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredCareProtocolAllocationStatus.granted || next == TieredCareProtocolAllocationStatus.revoked
            case .granted:
                return next == TieredCareProtocolAllocationStatus.expired
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

        func moveTo(_ next: TieredCareProtocolAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care protocol allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((rate - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareProtocolAllocation {
            return TieredCareProtocolAllocation(
                code: code,
                title: title,
                unit: unit,
                reviewer: reviewer,
                summary: summary,
                endsAt: endsAt,
                rate: rate,
                refills: refills,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered care protocol allocation in status requested.
    static func newTieredCareProtocolAllocation(_ code: String, title: String) -> TieredCareProtocolAllocation {
        return TieredCareProtocolAllocation(
            code: code,
            title: title,
            unit: "",
            reviewer: "",
            summary: "",
            endsAt: 0,
            rate: 0.0,
            refills: 0,
            procedureCode: "",
            status: TieredCareProtocolAllocationStatus.requested
        )
    }
}
