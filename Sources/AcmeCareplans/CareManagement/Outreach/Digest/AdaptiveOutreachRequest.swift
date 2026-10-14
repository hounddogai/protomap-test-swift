import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive outreach request is in its life cycle.
    enum AdaptiveOutreachRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive outreach request. Its code is unique within a tenant.
    final class AdaptiveOutreachRequest {
        var code: String
        var title: String
        var copay: Double
        var description: String
        var windowDays: Int
        var currency: String
        var status: AdaptiveOutreachRequestStatus

        init(code: String, title: String, copay: Double, description: String, windowDays: Int, currency: String, status: AdaptiveOutreachRequestStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.description = description
            self.windowDays = windowDays
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveOutreachRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptiveOutreachRequestStatus.warming || next == AdaptiveOutreachRequestStatus.ready
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AdaptiveOutreachRequestStatus.draining || next == AdaptiveOutreachRequestStatus.stopped
            case .draining:
                return next == AdaptiveOutreachRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveOutreachRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive outreach request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return (copay * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOutreachRequest {
            return AdaptiveOutreachRequest(
                code: code,
                title: title,
                copay: copay,
                description: description,
                windowDays: windowDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive outreach request in status idle.
    static func newAdaptiveOutreachRequest(_ code: String, title: String) -> AdaptiveOutreachRequest {
        return AdaptiveOutreachRequest(
            code: code,
            title: title,
            copay: 0.0,
            description: "",
            windowDays: 0,
            currency: "",
            status: AdaptiveOutreachRequestStatus.idle
        )
    }
}
