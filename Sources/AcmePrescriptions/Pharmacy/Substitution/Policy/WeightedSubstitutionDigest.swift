import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted substitution digest is in its life cycle.
    enum WeightedSubstitutionDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted substitution digest and its current status.
    final class WeightedSubstitutionDigest {
        var code: String
        var label: String
        var budget: Double
        var notes: String
        var startsAt: Int
        var bed: String
        var visitMinutes: Int
        var maximum: Double
        var patientRef: String
        var status: WeightedSubstitutionDigestStatus

        init(code: String, label: String, budget: Double, notes: String, startsAt: Int, bed: String, visitMinutes: Int, maximum: Double, patientRef: String, status: WeightedSubstitutionDigestStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.notes = notes
            self.startsAt = startsAt
            self.bed = bed
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.patientRef = patientRef
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

        func canMoveTo(_ next: WeightedSubstitutionDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedSubstitutionDigestStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedSubstitutionDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSubstitutionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted substitution digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(startsAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSubstitutionDigest {
            return WeightedSubstitutionDigest(
                code: code,
                label: label,
                budget: budget,
                notes: notes,
                startsAt: startsAt,
                bed: bed,
                visitMinutes: visitMinutes,
                maximum: maximum,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted substitution digest in status requested.
    static func newWeightedSubstitutionDigest(_ code: String, label: String) -> WeightedSubstitutionDigest {
        return WeightedSubstitutionDigest(
            code: code,
            label: label,
            budget: 0.0,
            notes: "",
            startsAt: 0,
            bed: "",
            visitMinutes: 0,
            maximum: 0.0,
            patientRef: "",
            status: WeightedSubstitutionDigestStatus.requested
        )
    }
}
