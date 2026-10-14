import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling program draft is in its life cycle.
    enum RollingProgramDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling program draft. Its code is unique within a tenant.
    final class RollingProgramDraft {
        var code: String
        var name: String
        var title: String
        var copay: Double
        var updatedAt: Int
        var discount: Double
        var channel: String
        var locale: String
        var visitMinutes: Int
        var procedureCode: String
        var margin: Double
        var status: RollingProgramDraftStatus

        init(code: String, name: String, title: String, copay: Double, updatedAt: Int, discount: Double, channel: String, locale: String, visitMinutes: Int, procedureCode: String, margin: Double, status: RollingProgramDraftStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.copay = copay
            self.updatedAt = updatedAt
            self.discount = discount
            self.channel = channel
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.margin = margin
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

        func canMoveTo(_ next: RollingProgramDraftStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RollingProgramDraftStatus.cancelled
            case .completed:
                return next == RollingProgramDraftStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingProgramDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling program draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling program draft") \(code)"
        }

        func netTotal() -> Double {
            return (margin * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingProgramDraft {
            return RollingProgramDraft(
                code: code,
                name: name,
                title: title,
                copay: copay,
                updatedAt: updatedAt,
                discount: discount,
                channel: channel,
                locale: locale,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling program draft in status planned.
    static func newRollingProgramDraft(_ code: String, name: String) -> RollingProgramDraft {
        return RollingProgramDraft(
            code: code,
            name: name,
            title: "",
            copay: 0.0,
            updatedAt: 0,
            discount: 0.0,
            channel: "",
            locale: "",
            visitMinutes: 0,
            procedureCode: "",
            margin: 0.0,
            status: RollingProgramDraftStatus.planned
        )
    }
}
