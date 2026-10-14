import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy draft is in its life cycle.
    enum LenientProxyDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient proxy draft, with what the planners need to act on it.
    final class LenientProxyDraft {
        var code: String
        var name: String
        var locale: String
        var ward: String
        var threshold: Double
        var title: String
        var region: String
        var retries: Int
        var channel: String
        var status: LenientProxyDraftStatus

        init(code: String, name: String, locale: String, ward: String, threshold: Double, title: String, region: String, retries: Int, channel: String, status: LenientProxyDraftStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.ward = ward
            self.threshold = threshold
            self.title = title
            self.region = region
            self.retries = retries
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProxyDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientProxyDraftStatus.approved || next == LenientProxyDraftStatus.rejected
            case .approved:
                return next == LenientProxyDraftStatus.rejected
            case .rejected:
                return next == LenientProxyDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient proxy draft") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(retries) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxyDraft {
            return LenientProxyDraft(
                code: code,
                name: name,
                locale: locale,
                ward: ward,
                threshold: threshold,
                title: title,
                region: region,
                retries: retries,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient proxy draft in status proposed.
    static func newLenientProxyDraft(_ code: String, name: String) -> LenientProxyDraft {
        return LenientProxyDraft(
            code: code,
            name: name,
            locale: "",
            ward: "",
            threshold: 0.0,
            title: "",
            region: "",
            retries: 0,
            channel: "",
            status: LenientProxyDraftStatus.proposed
        )
    }
}
