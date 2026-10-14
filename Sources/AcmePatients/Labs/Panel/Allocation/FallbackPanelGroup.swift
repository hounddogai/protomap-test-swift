import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback panel group is in its life cycle.
    enum FallbackPanelGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback panel group. Its code is unique within a tenant.
    final class FallbackPanelGroup {
        var code: String
        var name: String
        var reviewer: String
        var ceiling: Double
        var durationMinutes: Int
        var expiresAt: Int
        var acuity: Int
        var dosageMg: Double
        var startsAt: Int
        var status: FallbackPanelGroupStatus

        init(code: String, name: String, reviewer: String, ceiling: Double, durationMinutes: Int, expiresAt: Int, acuity: Int, dosageMg: Double, startsAt: Int, status: FallbackPanelGroupStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: FallbackPanelGroupStatus) -> Bool {
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
                return next == FallbackPanelGroupStatus.rejected || next == FallbackPanelGroupStatus.withdrawn
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

        func moveTo(_ next: FallbackPanelGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback panel group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback panel group") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(startsAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPanelGroup {
            return FallbackPanelGroup(
                code: code,
                name: name,
                reviewer: reviewer,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                acuity: acuity,
                dosageMg: dosageMg,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback panel group in status proposed.
    static func newFallbackPanelGroup(_ code: String, name: String) -> FallbackPanelGroup {
        return FallbackPanelGroup(
            code: code,
            name: name,
            reviewer: "",
            ceiling: 0.0,
            durationMinutes: 0,
            expiresAt: 0,
            acuity: 0,
            dosageMg: 0.0,
            startsAt: 0,
            status: FallbackPanelGroupStatus.proposed
        )
    }
}
