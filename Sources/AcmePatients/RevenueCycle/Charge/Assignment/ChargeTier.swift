import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge tier is in its life cycle.
    enum ChargeTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a charge tier and its current status.
    final class ChargeTier {
        var code: String
        var name: String
        var endsAt: Int
        var revision: Int
        var floorValue: Double
        var acuity: Int
        var status: ChargeTierStatus

        init(code: String, name: String, endsAt: Int, revision: Int, floorValue: Double, acuity: Int, status: ChargeTierStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.revision = revision
            self.floorValue = floorValue
            self.acuity = acuity
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

        func canMoveTo(_ next: ChargeTierStatus) -> Bool {
            switch status {
            case .draft:
                return next == ChargeTierStatus.active || next == ChargeTierStatus.closed
            case .pending:
                return next == ChargeTierStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ChargeTierStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return (Double(acuity) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ChargeTier {
            return ChargeTier(
                code: code,
                name: name,
                endsAt: endsAt,
                revision: revision,
                floorValue: floorValue,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge tier in status draft.
    static func newChargeTier(_ code: String, name: String) -> ChargeTier {
        return ChargeTier(
            code: code,
            name: name,
            endsAt: 0,
            revision: 0,
            floorValue: 0.0,
            acuity: 0,
            status: ChargeTierStatus.draft
        )
    }
}
