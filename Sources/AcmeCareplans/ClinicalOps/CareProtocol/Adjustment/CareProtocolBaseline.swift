import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol baseline is in its life cycle.
    enum CareProtocolBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a care protocol baseline and its current status.
    final class CareProtocolBaseline {
        var code: String
        var title: String
        var rate: Double
        var bed: String
        var sequence: Int
        var archived: Bool
        var status: CareProtocolBaselineStatus

        init(code: String, title: String, rate: Double, bed: String, sequence: Int, archived: Bool, status: CareProtocolBaselineStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.bed = bed
            self.sequence = sequence
            self.archived = archived
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

        func canMoveTo(_ next: CareProtocolBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolBaselineStatus.active || next == CareProtocolBaselineStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareProtocolBaselineStatus.suspended
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

        func moveTo(_ next: CareProtocolBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol baseline") \(code)"
        }

        func projectedExposure() -> Double {
            return ((rate - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolBaseline {
            return CareProtocolBaseline(
                code: code,
                title: title,
                rate: rate,
                bed: bed,
                sequence: sequence,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol baseline in status draft.
    static func newCareProtocolBaseline(_ code: String, title: String) -> CareProtocolBaseline {
        return CareProtocolBaseline(
            code: code,
            title: title,
            rate: 0.0,
            bed: "",
            sequence: 0,
            archived: false,
            status: CareProtocolBaselineStatus.draft
        )
    }
}
