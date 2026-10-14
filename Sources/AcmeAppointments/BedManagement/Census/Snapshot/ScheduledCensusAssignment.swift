import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled census assignment is in its life cycle.
    enum ScheduledCensusAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled census assignment. Its code is unique within a tenant.
    final class ScheduledCensusAssignment {
        var code: String
        var label: String
        var payer: String
        var refills: Int
        var floorValue: Double
        var source: String
        var summary: String
        var diagnosisCode: String
        var quantity: Int
        var procedureCode: String
        var startsAt: Int
        var status: ScheduledCensusAssignmentStatus

        init(code: String, label: String, payer: String, refills: Int, floorValue: Double, source: String, summary: String, diagnosisCode: String, quantity: Int, procedureCode: String, startsAt: Int, status: ScheduledCensusAssignmentStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.refills = refills
            self.floorValue = floorValue
            self.source = source
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCensusAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ScheduledCensusAssignmentStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledCensusAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled census assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((Double(startsAt) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCensusAssignment {
            return ScheduledCensusAssignment(
                code: code,
                label: label,
                payer: payer,
                refills: refills,
                floorValue: floorValue,
                source: source,
                summary: summary,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                procedureCode: procedureCode,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled census assignment in status idle.
    static func newScheduledCensusAssignment(_ code: String, label: String) -> ScheduledCensusAssignment {
        return ScheduledCensusAssignment(
            code: code,
            label: label,
            payer: "",
            refills: 0,
            floorValue: 0.0,
            source: "",
            summary: "",
            diagnosisCode: "",
            quantity: 0,
            procedureCode: "",
            startsAt: 0,
            status: ScheduledCensusAssignmentStatus.idle
        )
    }
}
