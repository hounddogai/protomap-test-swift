import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling modality audit is in its life cycle.
    enum RollingModalityAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling modality audit. Its code is unique within a tenant.
    final class RollingModalityAudit {
        var code: String
        var title: String
        var score: Double
        var locale: String
        var unit: String
        var payer: String
        var segment: String
        var ceiling: Double
        var priority: Int
        var tags: [String]
        var pinned: Bool
        var status: RollingModalityAuditStatus

        init(code: String, title: String, score: Double, locale: String, unit: String, payer: String, segment: String, ceiling: Double, priority: Int, tags: [String], pinned: Bool, status: RollingModalityAuditStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.locale = locale
            self.unit = unit
            self.payer = payer
            self.segment = segment
            self.ceiling = ceiling
            self.priority = priority
            self.tags = tags
            self.pinned = pinned
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

        func canMoveTo(_ next: RollingModalityAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingModalityAuditStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RollingModalityAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingModalityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling modality audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func netVolume() -> Double {
            return (ceiling * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> RollingModalityAudit {
            return RollingModalityAudit(
                code: code,
                title: title,
                score: score,
                locale: locale,
                unit: unit,
                payer: payer,
                segment: segment,
                ceiling: ceiling,
                priority: priority,
                tags: tags,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling modality audit in status requested.
    static func newRollingModalityAudit(_ code: String, title: String) -> RollingModalityAudit {
        return RollingModalityAudit(
            code: code,
            title: title,
            score: 0.0,
            locale: "",
            unit: "",
            payer: "",
            segment: "",
            ceiling: 0.0,
            priority: 0,
            tags: [],
            pinned: false,
            status: RollingModalityAuditStatus.requested
        )
    }
}
