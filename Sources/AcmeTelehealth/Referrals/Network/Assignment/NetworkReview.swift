import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network review is in its life cycle.
    enum NetworkReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A network review. Its code is unique within a tenant.
    final class NetworkReview {
        var code: String
        var name: String
        var tags: [String]
        var description: String
        var pinned: Bool
        var durationMinutes: Int
        var status: NetworkReviewStatus

        init(code: String, name: String, tags: [String], description: String, pinned: Bool, durationMinutes: Int, status: NetworkReviewStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.description = description
            self.pinned = pinned
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == NetworkReviewStatus.retired
            case .validated:
                return next == NetworkReviewStatus.published || next == NetworkReviewStatus.retired
            case .published:
                return next == NetworkReviewStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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
            return Double(durationMinutes)
        }

        func copyValue() -> NetworkReview {
            return NetworkReview(
                code: code,
                name: name,
                tags: tags,
                description: description,
                pinned: pinned,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a network review in status created.
    static func newNetworkReview(_ code: String, name: String) -> NetworkReview {
        return NetworkReview(
            code: code,
            name: name,
            tags: [],
            description: "",
            pinned: false,
            durationMinutes: 0,
            status: NetworkReviewStatus.created
        )
    }
}
