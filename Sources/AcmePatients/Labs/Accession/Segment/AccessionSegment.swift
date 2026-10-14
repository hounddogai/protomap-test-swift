import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession segment is in its life cycle.
    enum AccessionSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A accession segment as the accession team keeps it.
    final class AccessionSegment {
        var code: String
        var label: String
        var score: Double
        var ceiling: Double
        var patientRef: String
        var unit: String
        var status: AccessionSegmentStatus

        init(code: String, label: String, score: Double, ceiling: Double, patientRef: String, unit: String, status: AccessionSegmentStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.ceiling = ceiling
            self.patientRef = patientRef
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AccessionSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (ceiling * score * 100).rounded() / 100
        }

        func copyValue() -> AccessionSegment {
            return AccessionSegment(
                code: code,
                label: label,
                score: score,
                ceiling: ceiling,
                patientRef: patientRef,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a accession segment in status draft.
    static func newAccessionSegment(_ code: String, label: String) -> AccessionSegment {
        return AccessionSegment(
            code: code,
            label: label,
            score: 0.0,
            ceiling: 0.0,
            patientRef: "",
            unit: "",
            status: AccessionSegmentStatus.draft
        )
    }
}
