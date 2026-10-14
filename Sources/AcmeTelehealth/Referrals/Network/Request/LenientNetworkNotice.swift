import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient network notice is in its life cycle.
    enum LenientNetworkNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient network notice, with what the planners need to act on it.
    final class LenientNetworkNotice {
        var code: String
        var title: String
        var tags: [String]
        var unit: String
        var updatedAt: Int
        var archived: Bool
        var source: String
        var ceiling: Double
        var country: String
        var status: LenientNetworkNoticeStatus

        init(code: String, title: String, tags: [String], unit: String, updatedAt: Int, archived: Bool, source: String, ceiling: Double, country: String, status: LenientNetworkNoticeStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.unit = unit
            self.updatedAt = updatedAt
            self.archived = archived
            self.source = source
            self.ceiling = ceiling
            self.country = country
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

        func canMoveTo(_ next: LenientNetworkNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientNetworkNoticeStatus.approved || next == LenientNetworkNoticeStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientNetworkNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient network notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
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
            return (ceiling * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientNetworkNotice {
            return LenientNetworkNotice(
                code: code,
                title: title,
                tags: tags,
                unit: unit,
                updatedAt: updatedAt,
                archived: archived,
                source: source,
                ceiling: ceiling,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient network notice in status proposed.
    static func newLenientNetworkNotice(_ code: String, title: String) -> LenientNetworkNotice {
        return LenientNetworkNotice(
            code: code,
            title: title,
            tags: [],
            unit: "",
            updatedAt: 0,
            archived: false,
            source: "",
            ceiling: 0.0,
            country: "",
            status: LenientNetworkNoticeStatus.proposed
        )
    }
}
