import AcmePlatform
import Foundation

extension Consent {
    /// Where a language adjustment is in its life cycle.
    enum LanguageAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A language adjustment. Its code is unique within a tenant.
    final class LanguageAdjustment {
        var code: String
        var name: String
        var segment: String
        var phone: String
        var attempts: Int
        var visible: Bool
        var encounterID: String
        var windowDays: Int
        var status: LanguageAdjustmentStatus

        init(code: String, name: String, segment: String, phone: String, attempts: Int, visible: Bool, encounterID: String, windowDays: Int, status: LanguageAdjustmentStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.phone = phone
            self.attempts = attempts
            self.visible = visible
            self.encounterID = encounterID
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LanguageAdjustmentStatus.approved || next == LanguageAdjustmentStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LanguageAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(attempts) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageAdjustment {
            return LanguageAdjustment(
                code: code,
                name: name,
                segment: segment,
                phone: phone,
                attempts: attempts,
                visible: visible,
                encounterID: encounterID,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a language adjustment in status proposed.
    static func newLanguageAdjustment(_ code: String, name: String) -> LanguageAdjustment {
        return LanguageAdjustment(
            code: code,
            name: name,
            segment: "",
            phone: "",
            attempts: 0,
            visible: false,
            encounterID: "",
            windowDays: 0,
            status: LanguageAdjustmentStatus.proposed
        )
    }
}
