import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global substitution claim is in its life cycle.
    enum GlobalSubstitutionClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global substitution claim as the substitution team keeps it.
    final class GlobalSubstitutionClaim {
        var code: String
        var title: String
        var source: String
        var channel: String
        var segment: String
        var quantity: Int
        var maximum: Double
        var amount: Double
        var unit: String
        var status: GlobalSubstitutionClaimStatus

        init(code: String, title: String, source: String, channel: String, segment: String, quantity: Int, maximum: Double, amount: Double, unit: String, status: GlobalSubstitutionClaimStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.channel = channel
            self.segment = segment
            self.quantity = quantity
            self.maximum = maximum
            self.amount = amount
            self.unit = unit
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

        func canMoveTo(_ next: GlobalSubstitutionClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalSubstitutionClaimStatus.queued
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalSubstitutionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global substitution claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global substitution claim") \(code)"
        }

        func netTotal() -> Double {
            return ((maximum - amount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSubstitutionClaim {
            return GlobalSubstitutionClaim(
                code: code,
                title: title,
                source: source,
                channel: channel,
                segment: segment,
                quantity: quantity,
                maximum: maximum,
                amount: amount,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global substitution claim in status new.
    static func newGlobalSubstitutionClaim(_ code: String, title: String) -> GlobalSubstitutionClaim {
        return GlobalSubstitutionClaim(
            code: code,
            title: title,
            source: "",
            channel: "",
            segment: "",
            quantity: 0,
            maximum: 0.0,
            amount: 0.0,
            unit: "",
            status: GlobalSubstitutionClaimStatus.new
        )
    }
}
