import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result slot is in its life cycle.
    enum PendingResultSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One pending result slot, with what the planners need to act on it.
    final class PendingResultSlot {
        var code: String
        var name: String
        var discount: Double
        var createdAt: Int
        var source: String
        var ward: String
        var diagnosisCode: String
        var unit: String
        var ownerID: String
        var cost: Double
        var status: PendingResultSlotStatus

        init(code: String, name: String, discount: Double, createdAt: Int, source: String, ward: String, diagnosisCode: String, unit: String, ownerID: String, cost: Double, status: PendingResultSlotStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.createdAt = createdAt
            self.source = source
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.ownerID = ownerID
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingResultSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingResultSlotStatus.validated || next == PendingResultSlotStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingResultSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((cost - discount) * 100).rounded() / 100
        }

        func copyValue() -> PendingResultSlot {
            return PendingResultSlot(
                code: code,
                name: name,
                discount: discount,
                createdAt: createdAt,
                source: source,
                ward: ward,
                diagnosisCode: diagnosisCode,
                unit: unit,
                ownerID: ownerID,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending result slot in status created.
    static func newPendingResultSlot(_ code: String, name: String) -> PendingResultSlot {
        return PendingResultSlot(
            code: code,
            name: name,
            discount: 0.0,
            createdAt: 0,
            source: "",
            ward: "",
            diagnosisCode: "",
            unit: "",
            ownerID: "",
            cost: 0.0,
            status: PendingResultSlotStatus.created
        )
    }
}
