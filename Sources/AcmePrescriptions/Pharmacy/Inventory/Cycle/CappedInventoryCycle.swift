import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped inventory cycle is in its life cycle.
    enum CappedInventoryCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a capped inventory cycle and its current status.
    final class CappedInventoryCycle {
        var code: String
        var name: String
        var expiresAt: Int
        var diagnosisCode: String
        var sequence: Int
        var patientRef: String
        var limit: Int
        var status: CappedInventoryCycleStatus

        init(code: String, name: String, expiresAt: Int, diagnosisCode: String, sequence: Int, patientRef: String, limit: Int, status: CappedInventoryCycleStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.patientRef = patientRef
            self.limit = limit
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

        func canMoveTo(_ next: CappedInventoryCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedInventoryCycleStatus.validated || next == CappedInventoryCycleStatus.published
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedInventoryCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped inventory cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return (Double(limit) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> CappedInventoryCycle {
            return CappedInventoryCycle(
                code: code,
                name: name,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                patientRef: patientRef,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped inventory cycle in status created.
    static func newCappedInventoryCycle(_ code: String, name: String) -> CappedInventoryCycle {
        return CappedInventoryCycle(
            code: code,
            name: name,
            expiresAt: 0,
            diagnosisCode: "",
            sequence: 0,
            patientRef: "",
            limit: 0,
            status: CappedInventoryCycleStatus.created
        )
    }
}
