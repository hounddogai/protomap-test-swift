import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap milestone is in its life cycle.
    enum CareGapMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a care gap milestone and its current status.
    final class CareGapMilestone {
        var code: String
        var name: String
        var specialty: String
        var score: Double
        var unit: String
        var description: String
        var sequence: Int
        var copay: Double
        var refills: Int
        var status: CareGapMilestoneStatus

        init(code: String, name: String, specialty: String, score: Double, unit: String, description: String, sequence: Int, copay: Double, refills: Int, status: CareGapMilestoneStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.score = score
            self.unit = unit
            self.description = description
            self.sequence = sequence
            self.copay = copay
            self.refills = refills
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

        func canMoveTo(_ next: CareGapMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CareGapMilestoneStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CareGapMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap milestone") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(sequence) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> CareGapMilestone {
            return CareGapMilestone(
                code: code,
                name: name,
                specialty: specialty,
                score: score,
                unit: unit,
                description: description,
                sequence: sequence,
                copay: copay,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a care gap milestone in status open.
    static func newCareGapMilestone(_ code: String, name: String) -> CareGapMilestone {
        return CareGapMilestone(
            code: code,
            name: name,
            specialty: "",
            score: 0.0,
            unit: "",
            description: "",
            sequence: 0,
            copay: 0.0,
            refills: 0,
            status: CareGapMilestoneStatus.`open`
        )
    }
}
