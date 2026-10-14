import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding adjustment is in its life cycle.
    enum RoundingAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rounding adjustment, with what the planners need to act on it.
    final class RoundingAdjustment {
        var code: String
        var name: String
        var startsAt: Int
        var revision: Int
        var reviewer: String
        var archived: Bool
        var version: Int
        var discount: Double
        var ceiling: Double
        var status: RoundingAdjustmentStatus

        init(code: String, name: String, startsAt: Int, revision: Int, reviewer: String, archived: Bool, version: Int, discount: Double, ceiling: Double, status: RoundingAdjustmentStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.revision = revision
            self.reviewer = reviewer
            self.archived = archived
            self.version = version
            self.discount = discount
            self.ceiling = ceiling
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

        func canMoveTo(_ next: RoundingAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RoundingAdjustmentStatus.validated
            case .validated:
                return next == RoundingAdjustmentStatus.published || next == RoundingAdjustmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RoundingAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("rounding adjustment") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(version) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingAdjustment {
            return RoundingAdjustment(
                code: code,
                name: name,
                startsAt: startsAt,
                revision: revision,
                reviewer: reviewer,
                archived: archived,
                version: version,
                discount: discount,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding adjustment in status created.
    static func newRoundingAdjustment(_ code: String, name: String) -> RoundingAdjustment {
        return RoundingAdjustment(
            code: code,
            name: name,
            startsAt: 0,
            revision: 0,
            reviewer: "",
            archived: false,
            version: 0,
            discount: 0.0,
            ceiling: 0.0,
            status: RoundingAdjustmentStatus.created
        )
    }
}
