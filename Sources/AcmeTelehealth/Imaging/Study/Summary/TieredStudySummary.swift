import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study summary is in its life cycle.
    enum TieredStudySummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered study summary. Its code is unique within a tenant.
    final class TieredStudySummary {
        var code: String
        var name: String
        var patientRef: String
        var region: String
        var createdAt: Int
        var pinned: Bool
        var priority: Int
        var status: TieredStudySummaryStatus

        init(code: String, name: String, patientRef: String, region: String, createdAt: Int, pinned: Bool, priority: Int, status: TieredStudySummaryStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.region = region
            self.createdAt = createdAt
            self.pinned = pinned
            self.priority = priority
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

        func canMoveTo(_ next: TieredStudySummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredStudySummaryStatus.revoked || next == TieredStudySummaryStatus.expired
            case .granted:
                return next == TieredStudySummaryStatus.revoked
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

        func moveTo(_ next: TieredStudySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return ((Double(createdAt) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredStudySummary {
            return TieredStudySummary(
                code: code,
                name: name,
                patientRef: patientRef,
                region: region,
                createdAt: createdAt,
                pinned: pinned,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered study summary in status requested.
    static func newTieredStudySummary(_ code: String, name: String) -> TieredStudySummary {
        return TieredStudySummary(
            code: code,
            name: name,
            patientRef: "",
            region: "",
            createdAt: 0,
            pinned: false,
            priority: 0,
            status: TieredStudySummaryStatus.requested
        )
    }
}
