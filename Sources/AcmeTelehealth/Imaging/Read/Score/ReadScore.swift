import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read score is in its life cycle.
    enum ReadScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A read score. Its code is unique within a tenant.
    final class ReadScore {
        var code: String
        var name: String
        var batchSize: Int
        var margin: Double
        var category: String
        var sequence: Int
        var durationMinutes: Int
        var visitMinutes: Int
        var description: String
        var threshold: Double
        var windowDays: Int
        var status: ReadScoreStatus

        init(code: String, name: String, batchSize: Int, margin: Double, category: String, sequence: Int, durationMinutes: Int, visitMinutes: Int, description: String, threshold: Double, windowDays: Int, status: ReadScoreStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.margin = margin
            self.category = category
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.visitMinutes = visitMinutes
            self.description = description
            self.threshold = threshold
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ReadScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ReadScoreStatus.reopened || next == ReadScoreStatus.archived
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: ReadScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return ((Double(sequence) - margin) * 100).rounded() / 100
        }

        func copyValue() -> ReadScore {
            return ReadScore(
                code: code,
                name: name,
                batchSize: batchSize,
                margin: margin,
                category: category,
                sequence: sequence,
                durationMinutes: durationMinutes,
                visitMinutes: visitMinutes,
                description: description,
                threshold: threshold,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a read score in status open.
    static func newReadScore(_ code: String, name: String) -> ReadScore {
        return ReadScore(
            code: code,
            name: name,
            batchSize: 0,
            margin: 0.0,
            category: "",
            sequence: 0,
            durationMinutes: 0,
            visitMinutes: 0,
            description: "",
            threshold: 0.0,
            windowDays: 0,
            status: ReadScoreStatus.`open`
        )
    }
}
