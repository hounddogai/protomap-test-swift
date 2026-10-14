import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict worklist mapping is in its life cycle.
    enum StrictWorklistMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict worklist mapping. Its code is unique within a tenant.
    final class StrictWorklistMapping {
        var code: String
        var title: String
        var timezone: String
        var sequence: Int
        var updatedAt: Int
        var acuity: Int
        var status: StrictWorklistMappingStatus

        init(code: String, title: String, timezone: String, sequence: Int, updatedAt: Int, acuity: Int, status: StrictWorklistMappingStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.acuity = acuity
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

        func canMoveTo(_ next: StrictWorklistMappingStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == StrictWorklistMappingStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictWorklistMappingStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictWorklistMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict worklist mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWorklistMapping {
            return StrictWorklistMapping(
                code: code,
                title: title,
                timezone: timezone,
                sequence: sequence,
                updatedAt: updatedAt,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict worklist mapping in status draft.
    static func newStrictWorklistMapping(_ code: String, title: String) -> StrictWorklistMapping {
        return StrictWorklistMapping(
            code: code,
            title: title,
            timezone: "",
            sequence: 0,
            updatedAt: 0,
            acuity: 0,
            status: StrictWorklistMappingStatus.draft
        )
    }
}
