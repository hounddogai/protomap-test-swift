import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert quota is in its life cycle.
    enum AlertQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a alert quota and its current status.
    final class AlertQuota {
        var code: String
        var name: String
        var revision: Int
        var discount: Double
        var minimum: Double
        var maximum: Double
        var batchSize: Int
        var retries: Int
        var weight: Double
        var status: AlertQuotaStatus

        init(code: String, name: String, revision: Int, discount: Double, minimum: Double, maximum: Double, batchSize: Int, retries: Int, weight: Double, status: AlertQuotaStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.discount = discount
            self.minimum = minimum
            self.maximum = maximum
            self.batchSize = batchSize
            self.retries = retries
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AlertQuotaStatus.ready
            case .ready:
                return next == AlertQuotaStatus.draining || next == AlertQuotaStatus.stopped
            case .draining:
                return next == AlertQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedVolume() -> Double {
            return (minimum * maximum * 100).rounded() / 100
        }

        func copyValue() -> AlertQuota {
            return AlertQuota(
                code: code,
                name: name,
                revision: revision,
                discount: discount,
                minimum: minimum,
                maximum: maximum,
                batchSize: batchSize,
                retries: retries,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert quota in status idle.
    static func newAlertQuota(_ code: String, name: String) -> AlertQuota {
        return AlertQuota(
            code: code,
            name: name,
            revision: 0,
            discount: 0.0,
            minimum: 0.0,
            maximum: 0.0,
            batchSize: 0,
            retries: 0,
            weight: 0.0,
            status: AlertQuotaStatus.idle
        )
    }
}
