import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global goal record is in its life cycle.
    enum GlobalGoalRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One global goal record, with what the planners need to act on it.
    final class GlobalGoalRecord {
        var code: String
        var title: String
        var ward: String
        var region: String
        var visible: Bool
        var weight: Double
        var timezone: String
        var attempts: Int
        var status: GlobalGoalRecordStatus

        init(code: String, title: String, ward: String, region: String, visible: Bool, weight: Double, timezone: String, attempts: Int, status: GlobalGoalRecordStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.region = region
            self.visible = visible
            self.weight = weight
            self.timezone = timezone
            self.attempts = attempts
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

        func canMoveTo(_ next: GlobalGoalRecordStatus) -> Bool {
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
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalGoalRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global goal record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((weight - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalGoalRecord {
            return GlobalGoalRecord(
                code: code,
                title: title,
                ward: ward,
                region: region,
                visible: visible,
                weight: weight,
                timezone: timezone,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global goal record in status draft.
    static func newGlobalGoalRecord(_ code: String, title: String) -> GlobalGoalRecord {
        return GlobalGoalRecord(
            code: code,
            title: title,
            ward: "",
            region: "",
            visible: false,
            weight: 0.0,
            timezone: "",
            attempts: 0,
            status: GlobalGoalRecordStatus.draft
        )
    }
}
