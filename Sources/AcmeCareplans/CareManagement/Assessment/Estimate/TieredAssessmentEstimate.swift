import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered assessment estimate is in its life cycle.
    enum TieredAssessmentEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One tiered assessment estimate, with what the planners need to act on it.
    final class TieredAssessmentEstimate {
        var code: String
        var label: String
        var patientRef: String
        var tags: [String]
        var retries: Int
        var weight: Double
        var source: String
        var specialty: String
        var quantity: Int
        var status: TieredAssessmentEstimateStatus

        init(code: String, label: String, patientRef: String, tags: [String], retries: Int, weight: Double, source: String, specialty: String, quantity: Int, status: TieredAssessmentEstimateStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.tags = tags
            self.retries = retries
            self.weight = weight
            self.source = source
            self.specialty = specialty
            self.quantity = quantity
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

        func canMoveTo(_ next: TieredAssessmentEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredAssessmentEstimateStatus.warming || next == TieredAssessmentEstimateStatus.draining
            case .warming:
                return next == TieredAssessmentEstimateStatus.ready || next == TieredAssessmentEstimateStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredAssessmentEstimateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredAssessmentEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered assessment estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return ((weight - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredAssessmentEstimate {
            return TieredAssessmentEstimate(
                code: code,
                label: label,
                patientRef: patientRef,
                tags: tags,
                retries: retries,
                weight: weight,
                source: source,
                specialty: specialty,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered assessment estimate in status idle.
    static func newTieredAssessmentEstimate(_ code: String, label: String) -> TieredAssessmentEstimate {
        return TieredAssessmentEstimate(
            code: code,
            label: label,
            patientRef: "",
            tags: [],
            retries: 0,
            weight: 0.0,
            source: "",
            specialty: "",
            quantity: 0,
            status: TieredAssessmentEstimateStatus.idle
        )
    }
}
