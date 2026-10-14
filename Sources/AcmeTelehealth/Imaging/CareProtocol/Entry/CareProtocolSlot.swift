import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol slot is in its life cycle.
    enum CareProtocolSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a care protocol slot and its current status.
    final class CareProtocolSlot {
        var code: String
        var title: String
        var minimum: Double
        var payer: String
        var budget: Double
        var active: Bool
        var startsAt: Int
        var refills: Int
        var status: CareProtocolSlotStatus

        init(code: String, title: String, minimum: Double, payer: String, budget: Double, active: Bool, startsAt: Int, refills: Int, status: CareProtocolSlotStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.payer = payer
            self.budget = budget
            self.active = active
            self.startsAt = startsAt
            self.refills = refills
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

        func canMoveTo(_ next: CareProtocolSlotStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolSlotStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareProtocolSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedVolume() -> Double {
            return ((Double(startsAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSlot {
            return CareProtocolSlot(
                code: code,
                title: title,
                minimum: minimum,
                payer: payer,
                budget: budget,
                active: active,
                startsAt: startsAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol slot in status requested.
    static func newCareProtocolSlot(_ code: String, title: String) -> CareProtocolSlot {
        return CareProtocolSlot(
            code: code,
            title: title,
            minimum: 0.0,
            payer: "",
            budget: 0.0,
            active: false,
            startsAt: 0,
            refills: 0,
            status: CareProtocolSlotStatus.requested
        )
    }
}
