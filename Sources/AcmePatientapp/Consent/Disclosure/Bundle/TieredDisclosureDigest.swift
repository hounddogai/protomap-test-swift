import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered disclosure digest is in its life cycle.
    enum TieredDisclosureDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered disclosure digest as the disclosure team keeps it.
    final class TieredDisclosureDigest {
        var code: String
        var title: String
        var rate: Double
        var expiresAt: Int
        var source: String
        var budget: Double
        var amount: Double
        var status: TieredDisclosureDigestStatus

        init(code: String, title: String, rate: Double, expiresAt: Int, source: String, budget: Double, amount: Double, status: TieredDisclosureDigestStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.expiresAt = expiresAt
            self.source = source
            self.budget = budget
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredDisclosureDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredDisclosureDigestStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: TieredDisclosureDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered disclosure digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return (budget * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredDisclosureDigest {
            return TieredDisclosureDigest(
                code: code,
                title: title,
                rate: rate,
                expiresAt: expiresAt,
                source: source,
                budget: budget,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered disclosure digest in status proposed.
    static func newTieredDisclosureDigest(_ code: String, title: String) -> TieredDisclosureDigest {
        return TieredDisclosureDigest(
            code: code,
            title: title,
            rate: 0.0,
            expiresAt: 0,
            source: "",
            budget: 0.0,
            amount: 0.0,
            status: TieredDisclosureDigestStatus.proposed
        )
    }
}
