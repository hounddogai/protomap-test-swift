import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending language window is in its life cycle.
    enum PendingLanguageWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a pending language window and its current status.
    final class PendingLanguageWindow {
        var code: String
        var name: String
        var limit: Int
        var locale: String
        var allergy: String
        var region: String
        var status: PendingLanguageWindowStatus

        init(code: String, name: String, limit: Int, locale: String, allergy: String, region: String, status: PendingLanguageWindowStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.locale = locale
            self.allergy = allergy
            self.region = region
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

        func canMoveTo(_ next: PendingLanguageWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PendingLanguageWindowStatus.rejected || next == PendingLanguageWindowStatus.withdrawn
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

        func moveTo(_ next: PendingLanguageWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending language window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending language window") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> PendingLanguageWindow {
            return PendingLanguageWindow(
                code: code,
                name: name,
                limit: limit,
                locale: locale,
                allergy: allergy,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending language window in status proposed.
    static func newPendingLanguageWindow(_ code: String, name: String) -> PendingLanguageWindow {
        return PendingLanguageWindow(
            code: code,
            name: name,
            limit: 0,
            locale: "",
            allergy: "",
            region: "",
            status: PendingLanguageWindowStatus.proposed
        )
    }
}
