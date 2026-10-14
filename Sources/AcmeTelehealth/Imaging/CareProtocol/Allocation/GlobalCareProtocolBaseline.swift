import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global care protocol baseline is in its life cycle.
    enum GlobalCareProtocolBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global care protocol baseline and its current status.
    final class GlobalCareProtocolBaseline {
        var code: String
        var title: String
        var checksum: String
        var endsAt: Int
        var summary: String
        var graceDays: Int
        var acuity: Int
        var expiresAt: Int
        var approved: Bool
        var procedureCode: String
        var status: GlobalCareProtocolBaselineStatus

        init(code: String, title: String, checksum: String, endsAt: Int, summary: String, graceDays: Int, acuity: Int, expiresAt: Int, approved: Bool, procedureCode: String, status: GlobalCareProtocolBaselineStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.endsAt = endsAt
            self.summary = summary
            self.graceDays = graceDays
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.approved = approved
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalCareProtocolBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GlobalCareProtocolBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCareProtocolBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care protocol baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((Double(expiresAt) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareProtocolBaseline {
            return GlobalCareProtocolBaseline(
                code: code,
                title: title,
                checksum: checksum,
                endsAt: endsAt,
                summary: summary,
                graceDays: graceDays,
                acuity: acuity,
                expiresAt: expiresAt,
                approved: approved,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global care protocol baseline in status planned.
    static func newGlobalCareProtocolBaseline(_ code: String, title: String) -> GlobalCareProtocolBaseline {
        return GlobalCareProtocolBaseline(
            code: code,
            title: title,
            checksum: "",
            endsAt: 0,
            summary: "",
            graceDays: 0,
            acuity: 0,
            expiresAt: 0,
            approved: false,
            procedureCode: "",
            status: GlobalCareProtocolBaselineStatus.planned
        )
    }
}
