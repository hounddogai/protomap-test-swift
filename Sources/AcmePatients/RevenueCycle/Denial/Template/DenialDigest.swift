import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial digest is in its life cycle.
    enum DenialDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A denial digest as the denial team keeps it.
    final class DenialDigest {
        var code: String
        var title: String
        var batchSize: Int
        var amount: Double
        var name: String
        var externalRef: String
        var minimum: Double
        var dosageMg: Double
        var ceiling: Double
        var rate: Double
        var active: Bool
        var status: DenialDigestStatus

        init(code: String, title: String, batchSize: Int, amount: Double, name: String, externalRef: String, minimum: Double, dosageMg: Double, ceiling: Double, rate: Double, active: Bool, status: DenialDigestStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.amount = amount
            self.name = name
            self.externalRef = externalRef
            self.minimum = minimum
            self.dosageMg = dosageMg
            self.ceiling = ceiling
            self.rate = rate
            self.active = active
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

        func canMoveTo(_ next: DenialDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
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
                return next == DenialDigestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("denial digest") \(code)"
        }

        func projectedValue() -> Double {
            return ((ceiling + minimum) * 100).rounded() / 100
        }

        func copyValue() -> DenialDigest {
            return DenialDigest(
                code: code,
                title: title,
                batchSize: batchSize,
                amount: amount,
                name: name,
                externalRef: externalRef,
                minimum: minimum,
                dosageMg: dosageMg,
                ceiling: ceiling,
                rate: rate,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial digest in status draft.
    static func newDenialDigest(_ code: String, title: String) -> DenialDigest {
        return DenialDigest(
            code: code,
            title: title,
            batchSize: 0,
            amount: 0.0,
            name: "",
            externalRef: "",
            minimum: 0.0,
            dosageMg: 0.0,
            ceiling: 0.0,
            rate: 0.0,
            active: false,
            status: DenialDigestStatus.draft
        )
    }
}
