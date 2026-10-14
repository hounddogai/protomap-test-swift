import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary substitution notice is in its life cycle.
    enum PrimarySubstitutionNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary substitution notice. Its code is unique within a tenant.
    final class PrimarySubstitutionNotice {
        var code: String
        var label: String
        var active: Bool
        var region: String
        var windowDays: Int
        var startsAt: Int
        var status: PrimarySubstitutionNoticeStatus

        init(code: String, label: String, active: Bool, region: String, windowDays: Int, startsAt: Int, status: PrimarySubstitutionNoticeStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.region = region
            self.windowDays = windowDays
            self.startsAt = startsAt
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

        func canMoveTo(_ next: PrimarySubstitutionNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimarySubstitutionNoticeStatus.rejected
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

        func moveTo(_ next: PrimarySubstitutionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary substitution notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return (Double(windowDays) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySubstitutionNotice {
            return PrimarySubstitutionNotice(
                code: code,
                label: label,
                active: active,
                region: region,
                windowDays: windowDays,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary substitution notice in status proposed.
    static func newPrimarySubstitutionNotice(_ code: String, label: String) -> PrimarySubstitutionNotice {
        return PrimarySubstitutionNotice(
            code: code,
            label: label,
            active: false,
            region: "",
            windowDays: 0,
            startsAt: 0,
            status: PrimarySubstitutionNoticeStatus.proposed
        )
    }
}
