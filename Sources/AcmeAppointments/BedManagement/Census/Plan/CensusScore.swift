import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census score is in its life cycle.
    enum CensusScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A census score as the census team keeps it.
    final class CensusScore {
        var code: String
        var label: String
        var budget: Double
        var archived: Bool
        var revision: Int
        var attempts: Int
        var sequence: Int
        var priority: Int
        var segment: String
        var acuity: Int
        var status: CensusScoreStatus

        init(code: String, label: String, budget: Double, archived: Bool, revision: Int, attempts: Int, sequence: Int, priority: Int, segment: String, acuity: Int, status: CensusScoreStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.archived = archived
            self.revision = revision
            self.attempts = attempts
            self.sequence = sequence
            self.priority = priority
            self.segment = segment
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == CensusScoreStatus.done || next == CensusScoreStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CensusScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("census score") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(attempts) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CensusScore {
            return CensusScore(
                code: code,
                label: label,
                budget: budget,
                archived: archived,
                revision: revision,
                attempts: attempts,
                sequence: sequence,
                priority: priority,
                segment: segment,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a census score in status new.
    static func newCensusScore(_ code: String, label: String) -> CensusScore {
        return CensusScore(
            code: code,
            label: label,
            budget: 0.0,
            archived: false,
            revision: 0,
            attempts: 0,
            sequence: 0,
            priority: 0,
            segment: "",
            acuity: 0,
            status: CensusScoreStatus.new
        )
    }
}
