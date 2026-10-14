import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive consent form bundle is in its life cycle.
    enum AdaptiveConsentFormBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a adaptive consent form bundle and its current status.
    final class AdaptiveConsentFormBundle {
        var code: String
        var title: String
        var maximum: Double
        var retries: Int
        var limit: Int
        var segment: String
        var checksum: String
        var durationMinutes: Int
        var ward: String
        var copay: Double
        var visible: Bool
        var status: AdaptiveConsentFormBundleStatus

        init(code: String, title: String, maximum: Double, retries: Int, limit: Int, segment: String, checksum: String, durationMinutes: Int, ward: String, copay: Double, visible: Bool, status: AdaptiveConsentFormBundleStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.retries = retries
            self.limit = limit
            self.segment = segment
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.copay = copay
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveConsentFormBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveConsentFormBundleStatus.resolved || next == AdaptiveConsentFormBundleStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == AdaptiveConsentFormBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveConsentFormBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive consent form bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((maximum - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveConsentFormBundle {
            return AdaptiveConsentFormBundle(
                code: code,
                title: title,
                maximum: maximum,
                retries: retries,
                limit: limit,
                segment: segment,
                checksum: checksum,
                durationMinutes: durationMinutes,
                ward: ward,
                copay: copay,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive consent form bundle in status open.
    static func newAdaptiveConsentFormBundle(_ code: String, title: String) -> AdaptiveConsentFormBundle {
        return AdaptiveConsentFormBundle(
            code: code,
            title: title,
            maximum: 0.0,
            retries: 0,
            limit: 0,
            segment: "",
            checksum: "",
            durationMinutes: 0,
            ward: "",
            copay: 0.0,
            visible: false,
            status: AdaptiveConsentFormBundleStatus.`open`
        )
    }
}
