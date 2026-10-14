import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling transfer segment is in its life cycle.
    enum RollingTransferSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling transfer segment. Its code is unique within a tenant.
    final class RollingTransferSegment {
        var code: String
        var name: String
        var payer: String
        var floorValue: Double
        var category: String
        var archived: Bool
        var ceiling: Double
        var weight: Double
        var expiresAt: Int
        var status: RollingTransferSegmentStatus

        init(code: String, name: String, payer: String, floorValue: Double, category: String, archived: Bool, ceiling: Double, weight: Double, expiresAt: Int, status: RollingTransferSegmentStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.floorValue = floorValue
            self.category = category
            self.archived = archived
            self.ceiling = ceiling
            self.weight = weight
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RollingTransferSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RollingTransferSegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingTransferSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling transfer segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(expiresAt) + weight) * 100).rounded() / 100
        }

        func copyValue() -> RollingTransferSegment {
            return RollingTransferSegment(
                code: code,
                name: name,
                payer: payer,
                floorValue: floorValue,
                category: category,
                archived: archived,
                ceiling: ceiling,
                weight: weight,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling transfer segment in status open.
    static func newRollingTransferSegment(_ code: String, name: String) -> RollingTransferSegment {
        return RollingTransferSegment(
            code: code,
            name: name,
            payer: "",
            floorValue: 0.0,
            category: "",
            archived: false,
            ceiling: 0.0,
            weight: 0.0,
            expiresAt: 0,
            status: RollingTransferSegmentStatus.`open`
        )
    }
}
