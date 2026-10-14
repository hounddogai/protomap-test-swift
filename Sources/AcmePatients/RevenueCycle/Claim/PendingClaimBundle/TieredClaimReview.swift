import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim review is in its life cycle.
    enum TieredClaimReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered claim review, with what the planners need to act on it.
    final class TieredClaimReview {
        var code: String
        var label: String
        var discount: Double
        var visible: Bool
        var unit: String
        var ownerID: String
        var tags: [String]
        var status: TieredClaimReviewStatus

        init(code: String, label: String, discount: Double, visible: Bool, unit: String, ownerID: String, tags: [String], status: TieredClaimReviewStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.visible = visible
            self.unit = unit
            self.ownerID = ownerID
            self.tags = tags
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

        func canMoveTo(_ next: TieredClaimReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: TieredClaimReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func copyValue() -> TieredClaimReview {
            return TieredClaimReview(
                code: code,
                label: label,
                discount: discount,
                visible: visible,
                unit: unit,
                ownerID: ownerID,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered claim review in status requested.
    static func newTieredClaimReview(_ code: String, label: String) -> TieredClaimReview {
        return TieredClaimReview(
            code: code,
            label: label,
            discount: 0.0,
            visible: false,
            unit: "",
            ownerID: "",
            tags: [],
            status: TieredClaimReviewStatus.requested
        )
    }
}
