import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime rollup is in its life cycle.
    enum OvertimeRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A overtime rollup. Its code is unique within a tenant.
    final class OvertimeRollup {
        var code: String
        var title: String
        var label: String
        var ward: String
        var batchSize: Int
        var endsAt: Int
        var startsAt: Int
        var windowDays: Int
        var name: String
        var status: OvertimeRollupStatus

        init(code: String, title: String, label: String, ward: String, batchSize: Int, endsAt: Int, startsAt: Int, windowDays: Int, name: String, status: OvertimeRollupStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.ward = ward
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.name = name
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

        func canMoveTo(_ next: OvertimeRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OvertimeRollupStatus.suspended || next == OvertimeRollupStatus.closed
            case .suspended:
                return next == OvertimeRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((Double(endsAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeRollup {
            return OvertimeRollup(
                code: code,
                title: title,
                label: label,
                ward: ward,
                batchSize: batchSize,
                endsAt: endsAt,
                startsAt: startsAt,
                windowDays: windowDays,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a overtime rollup in status draft.
    static func newOvertimeRollup(_ code: String, title: String) -> OvertimeRollup {
        return OvertimeRollup(
            code: code,
            title: title,
            label: "",
            ward: "",
            batchSize: 0,
            endsAt: 0,
            startsAt: 0,
            windowDays: 0,
            name: "",
            status: OvertimeRollupStatus.draft
        )
    }
}
