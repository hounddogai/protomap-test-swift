import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program notice is in its life cycle.
    enum ProgramNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program notice, with what the planners need to act on it.
    final class ProgramNotice {
        var code: String
        var title: String
        var maximum: Double
        var ward: String
        var rate: Double
        var status: ProgramNoticeStatus

        init(code: String, title: String, maximum: Double, ward: String, rate: Double, status: ProgramNoticeStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.ward = ward
            self.rate = rate
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

        func canMoveTo(_ next: ProgramNoticeStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ProgramNoticeStatus.suspended || next == ProgramNoticeStatus.closed
            case .suspended:
                return next == ProgramNoticeStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return (maximum * rate * 100).rounded() / 100
        }

        func copyValue() -> ProgramNotice {
            return ProgramNotice(code: code, title: title, maximum: maximum, ward: ward, rate: rate, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a program notice in status draft.
    static func newProgramNotice(_ code: String, title: String) -> ProgramNotice {
        return ProgramNotice(
            code: code,
            title: title,
            maximum: 0.0,
            ward: "",
            rate: 0.0,
            status: ProgramNoticeStatus.draft
        )
    }
}
