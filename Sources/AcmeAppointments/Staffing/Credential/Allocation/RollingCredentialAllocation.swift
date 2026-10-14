import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling credential allocation is in its life cycle.
    enum RollingCredentialAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling credential allocation and its current status.
    final class RollingCredentialAllocation {
        var code: String
        var title: String
        var currency: String
        var source: String
        var timezone: String
        var locale: String
        var region: String
        var cost: Double
        var quantity: Int
        var ownerID: String
        var batchSize: Int
        var status: RollingCredentialAllocationStatus

        init(code: String, title: String, currency: String, source: String, timezone: String, locale: String, region: String, cost: Double, quantity: Int, ownerID: String, batchSize: Int, status: RollingCredentialAllocationStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.source = source
            self.timezone = timezone
            self.locale = locale
            self.region = region
            self.cost = cost
            self.quantity = quantity
            self.ownerID = ownerID
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RollingCredentialAllocationStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingCredentialAllocationStatus.running || next == RollingCredentialAllocationStatus.done
            case .queued:
                return next == RollingCredentialAllocationStatus.running
            case .running:
                return next == RollingCredentialAllocationStatus.done || next == RollingCredentialAllocationStatus.failed
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

        func moveTo(_ next: RollingCredentialAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling credential allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(batchSize) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RollingCredentialAllocation {
            return RollingCredentialAllocation(
                code: code,
                title: title,
                currency: currency,
                source: source,
                timezone: timezone,
                locale: locale,
                region: region,
                cost: cost,
                quantity: quantity,
                ownerID: ownerID,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling credential allocation in status new.
    static func newRollingCredentialAllocation(_ code: String, title: String) -> RollingCredentialAllocation {
        return RollingCredentialAllocation(
            code: code,
            title: title,
            currency: "",
            source: "",
            timezone: "",
            locale: "",
            region: "",
            cost: 0.0,
            quantity: 0,
            ownerID: "",
            batchSize: 0,
            status: RollingCredentialAllocationStatus.new
        )
    }
}
