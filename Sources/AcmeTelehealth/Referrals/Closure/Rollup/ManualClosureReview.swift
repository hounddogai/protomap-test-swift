import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual closure review is in its life cycle.
    enum ManualClosureReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual closure review. Its code is unique within a tenant.
    final class ManualClosureReview {
        var code: String
        var name: String
        var archived: Bool
        var attributes: [String: String]
        var visible: Bool
        var ceiling: Double
        var capacity: Int
        var score: Double
        var tags: [String]
        var status: ManualClosureReviewStatus

        init(code: String, name: String, archived: Bool, attributes: [String: String], visible: Bool, ceiling: Double, capacity: Int, score: Double, tags: [String], status: ManualClosureReviewStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.attributes = attributes
            self.visible = visible
            self.ceiling = ceiling
            self.capacity = capacity
            self.score = score
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

        func canMoveTo(_ next: ManualClosureReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualClosureReviewStatus.granted || next == ManualClosureReviewStatus.expired
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

        func moveTo(_ next: ManualClosureReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual closure review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedLoad() -> Double {
            return (ceiling * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> ManualClosureReview {
            return ManualClosureReview(
                code: code,
                name: name,
                archived: archived,
                attributes: attributes,
                visible: visible,
                ceiling: ceiling,
                capacity: capacity,
                score: score,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual closure review in status requested.
    static func newManualClosureReview(_ code: String, name: String) -> ManualClosureReview {
        return ManualClosureReview(
            code: code,
            name: name,
            archived: false,
            attributes: [:],
            visible: false,
            ceiling: 0.0,
            capacity: 0,
            score: 0.0,
            tags: [],
            status: ManualClosureReviewStatus.requested
        )
    }
}
