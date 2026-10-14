import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default shift score is in its life cycle.
    enum DefaultShiftScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default shift score and its current status.
    final class DefaultShiftScore {
        var code: String
        var name: String
        var rate: Double
        var source: String
        var description: String
        var revision: Int
        var status: DefaultShiftScoreStatus

        init(code: String, name: String, rate: Double, source: String, description: String, revision: Int, status: DefaultShiftScoreStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.source = source
            self.description = description
            self.revision = revision
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

        func canMoveTo(_ next: DefaultShiftScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultShiftScoreStatus.queued || next == DefaultShiftScoreStatus.running
            case .queued:
                switch next {
                case .done, .failed:
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
                return next == DefaultShiftScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultShiftScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default shift score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("default shift score") \(code)"
        }

        func netVolume() -> Double {
            return (Double(revision) * rate * 100).rounded() / 100
        }

        func copyValue() -> DefaultShiftScore {
            return DefaultShiftScore(
                code: code,
                name: name,
                rate: rate,
                source: source,
                description: description,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default shift score in status new.
    static func newDefaultShiftScore(_ code: String, name: String) -> DefaultShiftScore {
        return DefaultShiftScore(
            code: code,
            name: name,
            rate: 0.0,
            source: "",
            description: "",
            revision: 0,
            status: DefaultShiftScoreStatus.new
        )
    }
}
