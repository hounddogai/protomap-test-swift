import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read target is in its life cycle.
    enum TieredReadTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered read target and its current status.
    final class TieredReadTarget {
        var code: String
        var title: String
        var category: String
        var facility: String
        var margin: Double
        var reviewer: String
        var notes: String
        var limit: Int
        var status: TieredReadTargetStatus

        init(code: String, title: String, category: String, facility: String, margin: Double, reviewer: String, notes: String, limit: Int, status: TieredReadTargetStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.facility = facility
            self.margin = margin
            self.reviewer = reviewer
            self.notes = notes
            self.limit = limit
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

        func canMoveTo(_ next: TieredReadTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == TieredReadTargetStatus.revoked || next == TieredReadTargetStatus.expired
            case .revoked:
                return next == TieredReadTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReadTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((margin + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadTarget {
            return TieredReadTarget(
                code: code,
                title: title,
                category: category,
                facility: facility,
                margin: margin,
                reviewer: reviewer,
                notes: notes,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered read target in status requested.
    static func newTieredReadTarget(_ code: String, title: String) -> TieredReadTarget {
        return TieredReadTarget(
            code: code,
            title: title,
            category: "",
            facility: "",
            margin: 0.0,
            reviewer: "",
            notes: "",
            limit: 0,
            status: TieredReadTargetStatus.requested
        )
    }
}
