import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped care gap assignment is in its life cycle.
    enum CappedCareGapAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped care gap assignment and its current status.
    final class CappedCareGapAssignment {
        var code: String
        var label: String
        var source: String
        var floorValue: Double
        var refills: Int
        var startsAt: Int
        var status: CappedCareGapAssignmentStatus

        init(code: String, label: String, source: String, floorValue: Double, refills: Int, startsAt: Int, status: CappedCareGapAssignmentStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.floorValue = floorValue
            self.refills = refills
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CappedCareGapAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedCareGapAssignmentStatus.resolved || next == CappedCareGapAssignmentStatus.reopened
            case .resolved:
                return next == CappedCareGapAssignmentStatus.reopened || next == CappedCareGapAssignmentStatus.archived
            case .reopened:
                return next == CappedCareGapAssignmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return (floorValue * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareGapAssignment {
            return CappedCareGapAssignment(
                code: code,
                label: label,
                source: source,
                floorValue: floorValue,
                refills: refills,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped care gap assignment in status open.
    static func newCappedCareGapAssignment(_ code: String, label: String) -> CappedCareGapAssignment {
        return CappedCareGapAssignment(
            code: code,
            label: label,
            source: "",
            floorValue: 0.0,
            refills: 0,
            startsAt: 0,
            status: CappedCareGapAssignmentStatus.`open`
        )
    }
}
