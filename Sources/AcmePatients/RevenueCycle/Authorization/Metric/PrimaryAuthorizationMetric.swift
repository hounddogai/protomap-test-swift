import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary authorization metric is in its life cycle.
    enum PrimaryAuthorizationMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary authorization metric as the authorization team keeps it.
    final class PrimaryAuthorizationMetric {
        var code: String
        var label: String
        var reviewer: String
        var expiresAt: Int
        var batchSize: Int
        var ownerID: String
        var dosageMg: Double
        var status: PrimaryAuthorizationMetricStatus

        init(code: String, label: String, reviewer: String, expiresAt: Int, batchSize: Int, ownerID: String, dosageMg: Double, status: PrimaryAuthorizationMetricStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: PrimaryAuthorizationMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryAuthorizationMetricStatus.stopped
            case .warming:
                return next == PrimaryAuthorizationMetricStatus.ready || next == PrimaryAuthorizationMetricStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryAuthorizationMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAuthorizationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary authorization metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((Double(expiresAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAuthorizationMetric {
            return PrimaryAuthorizationMetric(
                code: code,
                label: label,
                reviewer: reviewer,
                expiresAt: expiresAt,
                batchSize: batchSize,
                ownerID: ownerID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary authorization metric in status idle.
    static func newPrimaryAuthorizationMetric(_ code: String, label: String) -> PrimaryAuthorizationMetric {
        return PrimaryAuthorizationMetric(
            code: code,
            label: label,
            reviewer: "",
            expiresAt: 0,
            batchSize: 0,
            ownerID: "",
            dosageMg: 0.0,
            status: PrimaryAuthorizationMetricStatus.idle
        )
    }
}
