import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive follow up baseline is in its life cycle.
    enum AdaptiveFollowUpBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive follow up baseline. Its code is unique within a tenant.
    final class AdaptiveFollowUpBaseline {
        var code: String
        var title: String
        var active: Bool
        var limit: Int
        var source: String
        var procedureCode: String
        var sequence: Int
        var patientRef: String
        var specialty: String
        var score: Double
        var margin: Double
        var status: AdaptiveFollowUpBaselineStatus

        init(code: String, title: String, active: Bool, limit: Int, source: String, procedureCode: String, sequence: Int, patientRef: String, specialty: String, score: Double, margin: Double, status: AdaptiveFollowUpBaselineStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.limit = limit
            self.source = source
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.patientRef = patientRef
            self.specialty = specialty
            self.score = score
            self.margin = margin
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

        func canMoveTo(_ next: AdaptiveFollowUpBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveFollowUpBaselineStatus.pending || next == AdaptiveFollowUpBaselineStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveFollowUpBaselineStatus.suspended || next == AdaptiveFollowUpBaselineStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveFollowUpBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive follow up baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return (margin * score * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFollowUpBaseline {
            return AdaptiveFollowUpBaseline(
                code: code,
                title: title,
                active: active,
                limit: limit,
                source: source,
                procedureCode: procedureCode,
                sequence: sequence,
                patientRef: patientRef,
                specialty: specialty,
                score: score,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive follow up baseline in status draft.
    static func newAdaptiveFollowUpBaseline(_ code: String, title: String) -> AdaptiveFollowUpBaseline {
        return AdaptiveFollowUpBaseline(
            code: code,
            title: title,
            active: false,
            limit: 0,
            source: "",
            procedureCode: "",
            sequence: 0,
            patientRef: "",
            specialty: "",
            score: 0.0,
            margin: 0.0,
            status: AdaptiveFollowUpBaselineStatus.draft
        )
    }
}
