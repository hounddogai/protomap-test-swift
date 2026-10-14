import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual care protocol review is in its life cycle.
    enum ManualCareProtocolReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual care protocol review as the care protocol team keeps it.
    final class ManualCareProtocolReview {
        var code: String
        var title: String
        var name: String
        var region: String
        var tags: [String]
        var discount: Double
        var status: ManualCareProtocolReviewStatus

        init(code: String, title: String, name: String, region: String, tags: [String], discount: Double, status: ManualCareProtocolReviewStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.region = region
            self.tags = tags
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualCareProtocolReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ManualCareProtocolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> ManualCareProtocolReview {
            return ManualCareProtocolReview(
                code: code,
                title: title,
                name: name,
                region: region,
                tags: tags,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual care protocol review in status requested.
    static func newManualCareProtocolReview(_ code: String, title: String) -> ManualCareProtocolReview {
        return ManualCareProtocolReview(
            code: code,
            title: title,
            name: "",
            region: "",
            tags: [],
            discount: 0.0,
            status: ManualCareProtocolReviewStatus.requested
        )
    }
}
