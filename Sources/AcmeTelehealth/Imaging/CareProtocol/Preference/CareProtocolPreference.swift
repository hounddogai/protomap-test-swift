import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol preference is in its life cycle.
    enum CareProtocolPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care protocol preference. Its code is unique within a tenant.
    final class CareProtocolPreference {
        var code: String
        var name: String
        var title: String
        var refills: Int
        var currency: String
        var status: CareProtocolPreferenceStatus

        init(code: String, name: String, title: String, refills: Int, currency: String, status: CareProtocolPreferenceStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.refills = refills
            self.currency = currency
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

        func canMoveTo(_ next: CareProtocolPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == CareProtocolPreferenceStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CareProtocolPreferenceStatus.completed || next == CareProtocolPreferenceStatus.cancelled
            case .completed:
                return next == CareProtocolPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> CareProtocolPreference {
            return CareProtocolPreference(
                code: code,
                name: name,
                title: title,
                refills: refills,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol preference in status planned.
    static func newCareProtocolPreference(_ code: String, name: String) -> CareProtocolPreference {
        return CareProtocolPreference(
            code: code,
            name: name,
            title: "",
            refills: 0,
            currency: "",
            status: CareProtocolPreferenceStatus.planned
        )
    }
}
