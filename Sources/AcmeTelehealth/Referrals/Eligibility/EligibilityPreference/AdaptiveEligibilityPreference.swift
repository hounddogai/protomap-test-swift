import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive eligibility preference is in its life cycle.
    enum AdaptiveEligibilityPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive eligibility preference. Its code is unique within a tenant.
    final class AdaptiveEligibilityPreference {
        var code: String
        var name: String
        var rate: Double
        var maximum: Double
        var country: String
        var sequence: Int
        var updatedAt: Int
        var bed: String
        var status: AdaptiveEligibilityPreferenceStatus

        init(code: String, name: String, rate: Double, maximum: Double, country: String, sequence: Int, updatedAt: Int, bed: String, status: AdaptiveEligibilityPreferenceStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.maximum = maximum
            self.country = country
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.bed = bed
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

        func canMoveTo(_ next: AdaptiveEligibilityPreferenceStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveEligibilityPreferenceStatus.queued
            case .queued:
                return next == AdaptiveEligibilityPreferenceStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AdaptiveEligibilityPreferenceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveEligibilityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive eligibility preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive eligibility preference") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(sequence) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveEligibilityPreference {
            return AdaptiveEligibilityPreference(
                code: code,
                name: name,
                rate: rate,
                maximum: maximum,
                country: country,
                sequence: sequence,
                updatedAt: updatedAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive eligibility preference in status new.
    static func newAdaptiveEligibilityPreference(_ code: String, name: String) -> AdaptiveEligibilityPreference {
        return AdaptiveEligibilityPreference(
            code: code,
            name: name,
            rate: 0.0,
            maximum: 0.0,
            country: "",
            sequence: 0,
            updatedAt: 0,
            bed: "",
            status: AdaptiveEligibilityPreferenceStatus.new
        )
    }
}
