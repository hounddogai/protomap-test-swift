import AcmePlatform
import Foundation

extension Consent {
    /// Where a language variance is in its life cycle.
    enum LanguageVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One language variance, with what the planners need to act on it.
    final class LanguageVariance {
        var code: String
        var title: String
        var approved: Bool
        var priority: Int
        var phone: String
        var visible: Bool
        var status: LanguageVarianceStatus

        init(code: String, title: String, approved: Bool, priority: Int, phone: String, visible: Bool, status: LanguageVarianceStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.priority = priority
            self.phone = phone
            self.visible = visible
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

        func canMoveTo(_ next: LanguageVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LanguageVarianceStatus.done || next == LanguageVarianceStatus.failed
            case .done:
                return next == LanguageVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language variance") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> LanguageVariance {
            return LanguageVariance(
                code: code,
                title: title,
                approved: approved,
                priority: priority,
                phone: phone,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a language variance in status new.
    static func newLanguageVariance(_ code: String, title: String) -> LanguageVariance {
        return LanguageVariance(
            code: code,
            title: title,
            approved: false,
            priority: 0,
            phone: "",
            visible: false,
            status: LanguageVarianceStatus.new
        )
    }
}
