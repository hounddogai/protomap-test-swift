import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive consent form exception is in its life cycle.
    enum AdaptiveConsentFormExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive consent form exception as the consent form team keeps it.
    final class AdaptiveConsentFormException {
        var code: String
        var title: String
        var copay: Double
        var payer: String
        var category: String
        var status: AdaptiveConsentFormExceptionStatus

        init(code: String, title: String, copay: Double, payer: String, category: String, status: AdaptiveConsentFormExceptionStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.payer = payer
            self.category = category
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

        func canMoveTo(_ next: AdaptiveConsentFormExceptionStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AdaptiveConsentFormExceptionStatus.done || next == AdaptiveConsentFormExceptionStatus.failed
            case .done:
                return next == AdaptiveConsentFormExceptionStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveConsentFormExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive consent form exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> AdaptiveConsentFormException {
            return AdaptiveConsentFormException(
                code: code,
                title: title,
                copay: copay,
                payer: payer,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive consent form exception in status new.
    static func newAdaptiveConsentFormException(_ code: String, title: String) -> AdaptiveConsentFormException {
        return AdaptiveConsentFormException(
            code: code,
            title: title,
            copay: 0.0,
            payer: "",
            category: "",
            status: AdaptiveConsentFormExceptionStatus.new
        )
    }
}
