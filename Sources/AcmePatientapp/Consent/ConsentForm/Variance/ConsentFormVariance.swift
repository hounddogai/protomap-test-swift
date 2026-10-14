import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form variance is in its life cycle.
    enum ConsentFormVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a consent form variance and its current status.
    final class ConsentFormVariance {
        var code: String
        var label: String
        var expiresAt: Int
        var quantity: Int
        var weight: Double
        var attempts: Int
        var status: ConsentFormVarianceStatus

        init(code: String, label: String, expiresAt: Int, quantity: Int, weight: Double, attempts: Int, status: ConsentFormVarianceStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.weight = weight
            self.attempts = attempts
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

        func canMoveTo(_ next: ConsentFormVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == ConsentFormVarianceStatus.published || next == ConsentFormVarianceStatus.retired
            case .validated:
                return next == ConsentFormVarianceStatus.published || next == ConsentFormVarianceStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ConsentFormVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("consent form variance") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(quantity) + weight) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormVariance {
            return ConsentFormVariance(
                code: code,
                label: label,
                expiresAt: expiresAt,
                quantity: quantity,
                weight: weight,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a consent form variance in status created.
    static func newConsentFormVariance(_ code: String, label: String) -> ConsentFormVariance {
        return ConsentFormVariance(
            code: code,
            label: label,
            expiresAt: 0,
            quantity: 0,
            weight: 0.0,
            attempts: 0,
            status: ConsentFormVarianceStatus.created
        )
    }
}
