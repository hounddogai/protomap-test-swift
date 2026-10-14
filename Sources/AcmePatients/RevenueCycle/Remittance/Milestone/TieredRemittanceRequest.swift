import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance request is in its life cycle.
    enum TieredRemittanceRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered remittance request. Its code is unique within a tenant.
    final class TieredRemittanceRequest {
        var code: String
        var title: String
        var region: String
        var archived: Bool
        var minimum: Double
        var threshold: Double
        var durationMinutes: Int
        var retries: Int
        var status: TieredRemittanceRequestStatus

        init(code: String, title: String, region: String, archived: Bool, minimum: Double, threshold: Double, durationMinutes: Int, retries: Int, status: TieredRemittanceRequestStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.archived = archived
            self.minimum = minimum
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredRemittanceRequestStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredRemittanceRequestStatus.published || next == TieredRemittanceRequestStatus.retired
            case .validated:
                return next == TieredRemittanceRequestStatus.published
            case .published:
                return next == TieredRemittanceRequestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRemittanceRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return (minimum * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceRequest {
            return TieredRemittanceRequest(
                code: code,
                title: title,
                region: region,
                archived: archived,
                minimum: minimum,
                threshold: threshold,
                durationMinutes: durationMinutes,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered remittance request in status created.
    static func newTieredRemittanceRequest(_ code: String, title: String) -> TieredRemittanceRequest {
        return TieredRemittanceRequest(
            code: code,
            title: title,
            region: "",
            archived: false,
            minimum: 0.0,
            threshold: 0.0,
            durationMinutes: 0,
            retries: 0,
            status: TieredRemittanceRequestStatus.created
        )
    }
}
