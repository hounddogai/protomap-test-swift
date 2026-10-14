import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback rounding preference is in its life cycle.
    enum FallbackRoundingPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback rounding preference. Its code is unique within a tenant.
    final class FallbackRoundingPreference {
        var code: String
        var name: String
        var limit: Int
        var source: String
        var graceDays: Int
        var specialty: String
        var summary: String
        var amount: Double
        var discount: Double
        var status: FallbackRoundingPreferenceStatus

        init(code: String, name: String, limit: Int, source: String, graceDays: Int, specialty: String, summary: String, amount: Double, discount: Double, status: FallbackRoundingPreferenceStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.source = source
            self.graceDays = graceDays
            self.specialty = specialty
            self.summary = summary
            self.amount = amount
            self.discount = discount
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

        func canMoveTo(_ next: FallbackRoundingPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackRoundingPreferenceStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FallbackRoundingPreferenceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRoundingPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback rounding preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback rounding preference") \(code)"
        }

        func adjustedValue() -> Double {
            return ((discount + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRoundingPreference {
            return FallbackRoundingPreference(
                code: code,
                name: name,
                limit: limit,
                source: source,
                graceDays: graceDays,
                specialty: specialty,
                summary: summary,
                amount: amount,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback rounding preference in status created.
    static func newFallbackRoundingPreference(_ code: String, name: String) -> FallbackRoundingPreference {
        return FallbackRoundingPreference(
            code: code,
            name: name,
            limit: 0,
            source: "",
            graceDays: 0,
            specialty: "",
            summary: "",
            amount: 0.0,
            discount: 0.0,
            status: FallbackRoundingPreferenceStatus.created
        )
    }
}
