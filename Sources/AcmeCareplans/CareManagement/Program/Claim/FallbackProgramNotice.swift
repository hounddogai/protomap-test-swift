import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback program notice is in its life cycle.
    enum FallbackProgramNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback program notice. Its code is unique within a tenant.
    final class FallbackProgramNotice {
        var code: String
        var label: String
        var floorValue: Double
        var acuity: Int
        var country: String
        var status: FallbackProgramNoticeStatus

        init(code: String, label: String, floorValue: Double, acuity: Int, country: String, status: FallbackProgramNoticeStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.acuity = acuity
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackProgramNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackProgramNoticeStatus.granted || next == FallbackProgramNoticeStatus.revoked
            case .granted:
                return next == FallbackProgramNoticeStatus.revoked || next == FallbackProgramNoticeStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackProgramNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback program notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback program notice") \(code)"
        }

        func netVolume() -> Double {
            return (floorValue * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackProgramNotice {
            return FallbackProgramNotice(
                code: code,
                label: label,
                floorValue: floorValue,
                acuity: acuity,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback program notice in status requested.
    static func newFallbackProgramNotice(_ code: String, label: String) -> FallbackProgramNotice {
        return FallbackProgramNotice(
            code: code,
            label: label,
            floorValue: 0.0,
            acuity: 0,
            country: "",
            status: FallbackProgramNoticeStatus.requested
        )
    }
}
