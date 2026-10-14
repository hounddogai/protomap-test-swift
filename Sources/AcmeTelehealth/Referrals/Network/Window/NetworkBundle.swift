import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network bundle is in its life cycle.
    enum NetworkBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a network bundle and its current status.
    final class NetworkBundle {
        var code: String
        var label: String
        var attempts: Int
        var acuity: Int
        var region: String
        var segment: String
        var amount: Double
        var status: NetworkBundleStatus

        init(code: String, label: String, attempts: Int, acuity: Int, region: String, segment: String, amount: Double, status: NetworkBundleStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.acuity = acuity
            self.region = region
            self.segment = segment
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: NetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("network bundle") \(code)"
        }

        func weightedVolume() -> Double {
            return (amount * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> NetworkBundle {
            return NetworkBundle(
                code: code,
                label: label,
                attempts: attempts,
                acuity: acuity,
                region: region,
                segment: segment,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a network bundle in status draft.
    static func newNetworkBundle(_ code: String, label: String) -> NetworkBundle {
        return NetworkBundle(
            code: code,
            label: label,
            attempts: 0,
            acuity: 0,
            region: "",
            segment: "",
            amount: 0.0,
            status: NetworkBundleStatus.draft
        )
    }
}
