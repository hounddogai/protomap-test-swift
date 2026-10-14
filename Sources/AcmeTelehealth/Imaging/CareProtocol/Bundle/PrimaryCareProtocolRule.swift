import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary care protocol rule is in its life cycle.
    enum PrimaryCareProtocolRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary care protocol rule as the care protocol team keeps it.
    final class PrimaryCareProtocolRule {
        var code: String
        var title: String
        var expiresAt: Int
        var specialty: String
        var attempts: Int
        var sequence: Int
        var score: Double
        var margin: Double
        var status: PrimaryCareProtocolRuleStatus

        init(code: String, title: String, expiresAt: Int, specialty: String, attempts: Int, sequence: Int, score: Double, margin: Double, status: PrimaryCareProtocolRuleStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.specialty = specialty
            self.attempts = attempts
            self.sequence = sequence
            self.score = score
            self.margin = margin
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

        func canMoveTo(_ next: PrimaryCareProtocolRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PrimaryCareProtocolRuleStatus.done
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

        func moveTo(_ next: PrimaryCareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary care protocol rule") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCareProtocolRule {
            return PrimaryCareProtocolRule(
                code: code,
                title: title,
                expiresAt: expiresAt,
                specialty: specialty,
                attempts: attempts,
                sequence: sequence,
                score: score,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary care protocol rule in status new.
    static func newPrimaryCareProtocolRule(_ code: String, title: String) -> PrimaryCareProtocolRule {
        return PrimaryCareProtocolRule(
            code: code,
            title: title,
            expiresAt: 0,
            specialty: "",
            attempts: 0,
            sequence: 0,
            score: 0.0,
            margin: 0.0,
            status: PrimaryCareProtocolRuleStatus.new
        )
    }
}
