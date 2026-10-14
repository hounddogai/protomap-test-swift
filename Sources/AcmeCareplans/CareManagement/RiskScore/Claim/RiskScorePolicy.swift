import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score policy is in its life cycle.
    enum RiskScorePolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A risk score policy. Its code is unique within a tenant.
    final class RiskScorePolicy {
        var code: String
        var title: String
        var attempts: Int
        var refills: Int
        var category: String
        var externalRef: String
        var sequence: Int
        var capacity: Int
        var attributes: [String: String]
        var threshold: Double
        var country: String
        var status: RiskScorePolicyStatus

        init(code: String, title: String, attempts: Int, refills: Int, category: String, externalRef: String, sequence: Int, capacity: Int, attributes: [String: String], threshold: Double, country: String, status: RiskScorePolicyStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.refills = refills
            self.category = category
            self.externalRef = externalRef
            self.sequence = sequence
            self.capacity = capacity
            self.attributes = attributes
            self.threshold = threshold
            self.country = country
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

        func canMoveTo(_ next: RiskScorePolicyStatus) -> Bool {
            switch status {
            case .new:
                return next == RiskScorePolicyStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RiskScorePolicyStatus.failed
            case .done:
                return next == RiskScorePolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScorePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedLoad() -> Double {
            return ((Double(attempts) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> RiskScorePolicy {
            return RiskScorePolicy(
                code: code,
                title: title,
                attempts: attempts,
                refills: refills,
                category: category,
                externalRef: externalRef,
                sequence: sequence,
                capacity: capacity,
                attributes: attributes,
                threshold: threshold,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a risk score policy in status new.
    static func newRiskScorePolicy(_ code: String, title: String) -> RiskScorePolicy {
        return RiskScorePolicy(
            code: code,
            title: title,
            attempts: 0,
            refills: 0,
            category: "",
            externalRef: "",
            sequence: 0,
            capacity: 0,
            attributes: [:],
            threshold: 0.0,
            country: "",
            status: RiskScorePolicyStatus.new
        )
    }
}
