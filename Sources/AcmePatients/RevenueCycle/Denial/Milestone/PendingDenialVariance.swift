import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending denial variance is in its life cycle.
    enum PendingDenialVarianceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending denial variance. Its code is unique within a tenant.
    final class PendingDenialVariance {
        var code: String
        var title: String
        var weight: Double
        var updatedAt: Int
        var limit: Int
        var status: PendingDenialVarianceStatus

        init(code: String, title: String, weight: Double, updatedAt: Int, limit: Int, status: PendingDenialVarianceStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.updatedAt = updatedAt
            self.limit = limit
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

        func canMoveTo(_ next: PendingDenialVarianceStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingDenialVarianceStatus.ready || next == PendingDenialVarianceStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingDenialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending denial variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((weight + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PendingDenialVariance {
            return PendingDenialVariance(
                code: code,
                title: title,
                weight: weight,
                updatedAt: updatedAt,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending denial variance in status idle.
    static func newPendingDenialVariance(_ code: String, title: String) -> PendingDenialVariance {
        return PendingDenialVariance(
            code: code,
            title: title,
            weight: 0.0,
            updatedAt: 0,
            limit: 0,
            status: PendingDenialVarianceStatus.idle
        )
    }
}
