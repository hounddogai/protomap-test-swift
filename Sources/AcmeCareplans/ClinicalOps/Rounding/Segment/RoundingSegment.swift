import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding segment is in its life cycle.
    enum RoundingSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a rounding segment and its current status.
    final class RoundingSegment {
        var code: String
        var name: String
        var limit: Int
        var procedureCode: String
        var weight: Double
        var externalRef: String
        var visitMinutes: Int
        var status: RoundingSegmentStatus

        init(code: String, name: String, limit: Int, procedureCode: String, weight: Double, externalRef: String, visitMinutes: Int, status: RoundingSegmentStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.procedureCode = procedureCode
            self.weight = weight
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: RoundingSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RoundingSegmentStatus.inReview || next == RoundingSegmentStatus.archived
            case .inReview:
                return next == RoundingSegmentStatus.reopened || next == RoundingSegmentStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RoundingSegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(visitMinutes) - weight) * 100).rounded() / 100
        }

        func copyValue() -> RoundingSegment {
            return RoundingSegment(
                code: code,
                name: name,
                limit: limit,
                procedureCode: procedureCode,
                weight: weight,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding segment in status open.
    static func newRoundingSegment(_ code: String, name: String) -> RoundingSegment {
        return RoundingSegment(
            code: code,
            name: name,
            limit: 0,
            procedureCode: "",
            weight: 0.0,
            externalRef: "",
            visitMinutes: 0,
            status: RoundingSegmentStatus.`open`
        )
    }
}
