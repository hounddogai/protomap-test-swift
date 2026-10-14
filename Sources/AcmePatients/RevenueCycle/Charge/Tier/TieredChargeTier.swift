import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered charge tier is in its life cycle.
    enum TieredChargeTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered charge tier as the charge team keeps it.
    final class TieredChargeTier {
        var code: String
        var name: String
        var copay: Double
        var description: String
        var revision: Int
        var cost: Double
        var diagnosisCode: String
        var status: TieredChargeTierStatus

        init(code: String, name: String, copay: Double, description: String, revision: Int, cost: Double, diagnosisCode: String, status: TieredChargeTierStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.description = description
            self.revision = revision
            self.cost = cost
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: TieredChargeTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredChargeTierStatus.inProgress || next == TieredChargeTierStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredChargeTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered charge tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("tiered charge tier") \(code)"
        }

        func weightedVolume() -> Double {
            return ((copay + cost) * 100).rounded() / 100
        }

        func copyValue() -> TieredChargeTier {
            return TieredChargeTier(
                code: code,
                name: name,
                copay: copay,
                description: description,
                revision: revision,
                cost: cost,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered charge tier in status planned.
    static func newTieredChargeTier(_ code: String, name: String) -> TieredChargeTier {
        return TieredChargeTier(
            code: code,
            name: name,
            copay: 0.0,
            description: "",
            revision: 0,
            cost: 0.0,
            diagnosisCode: "",
            status: TieredChargeTierStatus.planned
        )
    }
}
