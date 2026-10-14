import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist estimate is in its life cycle.
    enum WorklistEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One worklist estimate, with what the planners need to act on it.
    final class WorklistEstimate {
        var code: String
        var name: String
        var maximum: Double
        var bed: String
        var attributes: [String: String]
        var score: Double
        var visitMinutes: Int
        var notes: String
        var attempts: Int
        var windowDays: Int
        var sequence: Int
        var status: WorklistEstimateStatus

        init(code: String, name: String, maximum: Double, bed: String, attributes: [String: String], score: Double, visitMinutes: Int, notes: String, attempts: Int, windowDays: Int, sequence: Int, status: WorklistEstimateStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.bed = bed
            self.attributes = attributes
            self.score = score
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.attempts = attempts
            self.windowDays = windowDays
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == WorklistEstimateStatus.validated || next == WorklistEstimateStatus.published
            case .validated:
                return next == WorklistEstimateStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WorklistEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist estimate") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return ((Double(visitMinutes) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistEstimate {
            return WorklistEstimate(
                code: code,
                name: name,
                maximum: maximum,
                bed: bed,
                attributes: attributes,
                score: score,
                visitMinutes: visitMinutes,
                notes: notes,
                attempts: attempts,
                windowDays: windowDays,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist estimate in status created.
    static func newWorklistEstimate(_ code: String, name: String) -> WorklistEstimate {
        return WorklistEstimate(
            code: code,
            name: name,
            maximum: 0.0,
            bed: "",
            attributes: [:],
            score: 0.0,
            visitMinutes: 0,
            notes: "",
            attempts: 0,
            windowDays: 0,
            sequence: 0,
            status: WorklistEstimateStatus.created
        )
    }
}
