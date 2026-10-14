import AcmePlatform
import Foundation

extension Labs {
    /// Where a result checkpoint is in its life cycle.
    enum ResultCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A result checkpoint as the result team keeps it.
    final class ResultCheckpoint {
        var code: String
        var name: String
        var checksum: String
        var externalRef: String
        var source: String
        var amount: Double
        var status: ResultCheckpointStatus

        init(code: String, name: String, checksum: String, externalRef: String, source: String, amount: Double, status: ResultCheckpointStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.externalRef = externalRef
            self.source = source
            self.amount = amount
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

        func canMoveTo(_ next: ResultCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ResultCheckpointStatus.reopened || next == ResultCheckpointStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: ResultCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("result checkpoint") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ResultCheckpoint {
            return ResultCheckpoint(
                code: code,
                name: name,
                checksum: checksum,
                externalRef: externalRef,
                source: source,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a result checkpoint in status open.
    static func newResultCheckpoint(_ code: String, name: String) -> ResultCheckpoint {
        return ResultCheckpoint(
            code: code,
            name: name,
            checksum: "",
            externalRef: "",
            source: "",
            amount: 0.0,
            status: ResultCheckpointStatus.`open`
        )
    }
}
