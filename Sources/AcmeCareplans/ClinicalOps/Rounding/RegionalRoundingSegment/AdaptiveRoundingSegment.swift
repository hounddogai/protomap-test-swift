import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive rounding segment is in its life cycle.
    enum AdaptiveRoundingSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive rounding segment, with what the planners need to act on it.
    final class AdaptiveRoundingSegment {
        var code: String
        var name: String
        var priority: Int
        var limit: Int
        var procedureCode: String
        var margin: Double
        var endsAt: Int
        var floorValue: Double
        var score: Double
        var status: AdaptiveRoundingSegmentStatus

        init(code: String, name: String, priority: Int, limit: Int, procedureCode: String, margin: Double, endsAt: Int, floorValue: Double, score: Double, status: AdaptiveRoundingSegmentStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.limit = limit
            self.procedureCode = procedureCode
            self.margin = margin
            self.endsAt = endsAt
            self.floorValue = floorValue
            self.score = score
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

        func canMoveTo(_ next: AdaptiveRoundingSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveRoundingSegmentStatus.rejected || next == AdaptiveRoundingSegmentStatus.withdrawn
            case .approved:
                return next == AdaptiveRoundingSegmentStatus.rejected || next == AdaptiveRoundingSegmentStatus.withdrawn
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

        func moveTo(_ next: AdaptiveRoundingSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive rounding segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return ((score - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRoundingSegment {
            return AdaptiveRoundingSegment(
                code: code,
                name: name,
                priority: priority,
                limit: limit,
                procedureCode: procedureCode,
                margin: margin,
                endsAt: endsAt,
                floorValue: floorValue,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive rounding segment in status proposed.
    static func newAdaptiveRoundingSegment(_ code: String, name: String) -> AdaptiveRoundingSegment {
        return AdaptiveRoundingSegment(
            code: code,
            name: name,
            priority: 0,
            limit: 0,
            procedureCode: "",
            margin: 0.0,
            endsAt: 0,
            floorValue: 0.0,
            score: 0.0,
            status: AdaptiveRoundingSegmentStatus.proposed
        )
    }
}
