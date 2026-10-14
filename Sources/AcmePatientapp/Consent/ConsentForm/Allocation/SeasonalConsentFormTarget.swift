import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal consent form target is in its life cycle.
    enum SeasonalConsentFormTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal consent form target. Its code is unique within a tenant.
    final class SeasonalConsentFormTarget {
        var code: String
        var name: String
        var channel: String
        var visible: Bool
        var capacity: Int
        var clinicianID: String
        var graceDays: Int
        var margin: Double
        var facility: String
        var status: SeasonalConsentFormTargetStatus

        init(code: String, name: String, channel: String, visible: Bool, capacity: Int, clinicianID: String, graceDays: Int, margin: Double, facility: String, status: SeasonalConsentFormTargetStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.visible = visible
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.margin = margin
            self.facility = facility
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

        func canMoveTo(_ next: SeasonalConsentFormTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SeasonalConsentFormTargetStatus.suspended || next == SeasonalConsentFormTargetStatus.closed
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: SeasonalConsentFormTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal consent form target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal consent form target") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(capacity) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalConsentFormTarget {
            return SeasonalConsentFormTarget(
                code: code,
                name: name,
                channel: channel,
                visible: visible,
                capacity: capacity,
                clinicianID: clinicianID,
                graceDays: graceDays,
                margin: margin,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal consent form target in status draft.
    static func newSeasonalConsentFormTarget(_ code: String, name: String) -> SeasonalConsentFormTarget {
        return SeasonalConsentFormTarget(
            code: code,
            name: name,
            channel: "",
            visible: false,
            capacity: 0,
            clinicianID: "",
            graceDays: 0,
            margin: 0.0,
            facility: "",
            status: SeasonalConsentFormTargetStatus.draft
        )
    }
}
