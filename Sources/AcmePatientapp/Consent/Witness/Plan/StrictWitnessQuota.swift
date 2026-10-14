import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict witness quota is in its life cycle.
    enum StrictWitnessQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a strict witness quota and its current status.
    final class StrictWitnessQuota {
        var code: String
        var title: String
        var budget: Double
        var capacity: Int
        var procedureCode: String
        var visitMinutes: Int
        var segment: String
        var summary: String
        var reviewer: String
        var status: StrictWitnessQuotaStatus

        init(code: String, title: String, budget: Double, capacity: Int, procedureCode: String, visitMinutes: Int, segment: String, summary: String, reviewer: String, status: StrictWitnessQuotaStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.capacity = capacity
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.segment = segment
            self.summary = summary
            self.reviewer = reviewer
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

        func canMoveTo(_ next: StrictWitnessQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == StrictWitnessQuotaStatus.draining
            case .ready:
                return next == StrictWitnessQuotaStatus.stopped
            case .draining:
                return next == StrictWitnessQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictWitnessQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict witness quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict witness quota") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((budget + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWitnessQuota {
            return StrictWitnessQuota(
                code: code,
                title: title,
                budget: budget,
                capacity: capacity,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                segment: segment,
                summary: summary,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict witness quota in status idle.
    static func newStrictWitnessQuota(_ code: String, title: String) -> StrictWitnessQuota {
        return StrictWitnessQuota(
            code: code,
            title: title,
            budget: 0.0,
            capacity: 0,
            procedureCode: "",
            visitMinutes: 0,
            segment: "",
            summary: "",
            reviewer: "",
            status: StrictWitnessQuotaStatus.idle
        )
    }
}
