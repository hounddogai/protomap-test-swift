import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive bed board batch is in its life cycle.
    enum AdaptiveBedBoardBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive bed board batch. Its code is unique within a tenant.
    final class AdaptiveBedBoardBatch {
        var code: String
        var name: String
        var durationMinutes: Int
        var segment: String
        var sequence: Int
        var ratio: Double
        var status: AdaptiveBedBoardBatchStatus

        init(code: String, name: String, durationMinutes: Int, segment: String, sequence: Int, ratio: Double, status: AdaptiveBedBoardBatchStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.segment = segment
            self.sequence = sequence
            self.ratio = ratio
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

        func canMoveTo(_ next: AdaptiveBedBoardBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveBedBoardBatchStatus.validated || next == AdaptiveBedBoardBatchStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AdaptiveBedBoardBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveBedBoardBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive bed board batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive bed board batch") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(sequence) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveBedBoardBatch {
            return AdaptiveBedBoardBatch(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                segment: segment,
                sequence: sequence,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive bed board batch in status created.
    static func newAdaptiveBedBoardBatch(_ code: String, name: String) -> AdaptiveBedBoardBatch {
        return AdaptiveBedBoardBatch(
            code: code,
            name: name,
            durationMinutes: 0,
            segment: "",
            sequence: 0,
            ratio: 0.0,
            status: AdaptiveBedBoardBatchStatus.created
        )
    }
}
