import AcmePlatform
import Foundation

extension Consent {
    /// Where a language policy is in its life cycle.
    enum LanguagePolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A language policy. Its code is unique within a tenant.
    final class LanguagePolicy {
        var code: String
        var title: String
        var visible: Bool
        var weight: Double
        var discount: Double
        var specialty: String
        var attempts: Int
        var windowDays: Int
        var priority: Int
        var status: LanguagePolicyStatus

        init(code: String, title: String, visible: Bool, weight: Double, discount: Double, specialty: String, attempts: Int, windowDays: Int, priority: Int, status: LanguagePolicyStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.weight = weight
            self.discount = discount
            self.specialty = specialty
            self.attempts = attempts
            self.windowDays = windowDays
            self.priority = priority
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

        func canMoveTo(_ next: LanguagePolicyStatus) -> Bool {
            switch status {
            case .new:
                return next == LanguagePolicyStatus.queued || next == LanguagePolicyStatus.failed
            case .queued:
                return next == LanguagePolicyStatus.done || next == LanguagePolicyStatus.failed
            case .running:
                return next == LanguagePolicyStatus.done
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

        func moveTo(_ next: LanguagePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language policy") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(attempts) + discount) * 100).rounded() / 100
        }

        func copyValue() -> LanguagePolicy {
            return LanguagePolicy(
                code: code,
                title: title,
                visible: visible,
                weight: weight,
                discount: discount,
                specialty: specialty,
                attempts: attempts,
                windowDays: windowDays,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a language policy in status new.
    static func newLanguagePolicy(_ code: String, title: String) -> LanguagePolicy {
        return LanguagePolicy(
            code: code,
            title: title,
            visible: false,
            weight: 0.0,
            discount: 0.0,
            specialty: "",
            attempts: 0,
            windowDays: 0,
            priority: 0,
            status: LanguagePolicyStatus.new
        )
    }
}
