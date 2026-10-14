import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy quota is in its life cycle.
    enum ProxyQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A proxy quota. Its code is unique within a tenant.
    final class ProxyQuota {
        var code: String
        var label: String
        var minimum: Double
        var pinned: Bool
        var quantity: Int
        var retries: Int
        var budget: Double
        var active: Bool
        var segment: String
        var refills: Int
        var status: ProxyQuotaStatus

        init(code: String, label: String, minimum: Double, pinned: Bool, quantity: Int, retries: Int, budget: Double, active: Bool, segment: String, refills: Int, status: ProxyQuotaStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.pinned = pinned
            self.quantity = quantity
            self.retries = retries
            self.budget = budget
            self.active = active
            self.segment = segment
            self.refills = refills
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

        func canMoveTo(_ next: ProxyQuotaStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ProxyQuotaStatus.completed
            case .completed:
                return next == ProxyQuotaStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return (Double(retries) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ProxyQuota {
            return ProxyQuota(
                code: code,
                label: label,
                minimum: minimum,
                pinned: pinned,
                quantity: quantity,
                retries: retries,
                budget: budget,
                active: active,
                segment: segment,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a proxy quota in status planned.
    static func newProxyQuota(_ code: String, label: String) -> ProxyQuota {
        return ProxyQuota(
            code: code,
            label: label,
            minimum: 0.0,
            pinned: false,
            quantity: 0,
            retries: 0,
            budget: 0.0,
            active: false,
            segment: "",
            refills: 0,
            status: ProxyQuotaStatus.planned
        )
    }
}
