import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered revocation segment is in its life cycle.
    enum TieredRevocationSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered revocation segment and its current status.
    final class TieredRevocationSegment {
        var code: String
        var label: String
        var diagnosisCode: String
        var ceiling: Double
        var allergy: String
        var refills: Int
        var threshold: Double
        var status: TieredRevocationSegmentStatus

        init(code: String, label: String, diagnosisCode: String, ceiling: Double, allergy: String, refills: Int, threshold: Double, status: TieredRevocationSegmentStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.allergy = allergy
            self.refills = refills
            self.threshold = threshold
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

        func canMoveTo(_ next: TieredRevocationSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TieredRevocationSegmentStatus.active || next == TieredRevocationSegmentStatus.suspended
            case .active:
                return next == TieredRevocationSegmentStatus.suspended
            case .suspended:
                return next == TieredRevocationSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRevocationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered revocation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return (ceiling * threshold * 100).rounded() / 100
        }

        func copyValue() -> TieredRevocationSegment {
            return TieredRevocationSegment(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                allergy: allergy,
                refills: refills,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered revocation segment in status draft.
    static func newTieredRevocationSegment(_ code: String, label: String) -> TieredRevocationSegment {
        return TieredRevocationSegment(
            code: code,
            label: label,
            diagnosisCode: "",
            ceiling: 0.0,
            allergy: "",
            refills: 0,
            threshold: 0.0,
            status: TieredRevocationSegmentStatus.draft
        )
    }
}
