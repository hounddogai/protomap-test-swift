import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped charge threshold is in its life cycle.
    enum CappedChargeThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped charge threshold, with what the planners need to act on it.
    final class CappedChargeThreshold {
        var code: String
        var title: String
        var category: String
        var maximum: Double
        var tags: [String]
        var visible: Bool
        var country: String
        var updatedAt: Int
        var status: CappedChargeThresholdStatus

        init(code: String, title: String, category: String, maximum: Double, tags: [String], visible: Bool, country: String, updatedAt: Int, status: CappedChargeThresholdStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.maximum = maximum
            self.tags = tags
            self.visible = visible
            self.country = country
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedChargeThresholdStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CappedChargeThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedChargeThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped charge threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return (maximum * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedChargeThreshold {
            return CappedChargeThreshold(
                code: code,
                title: title,
                category: category,
                maximum: maximum,
                tags: tags,
                visible: visible,
                country: country,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped charge threshold in status draft.
    static func newCappedChargeThreshold(_ code: String, title: String) -> CappedChargeThreshold {
        return CappedChargeThreshold(
            code: code,
            title: title,
            category: "",
            maximum: 0.0,
            tags: [],
            visible: false,
            country: "",
            updatedAt: 0,
            status: CappedChargeThresholdStatus.draft
        )
    }
}
