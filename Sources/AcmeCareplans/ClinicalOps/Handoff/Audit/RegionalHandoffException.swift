import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional handoff exception is in its life cycle.
    enum RegionalHandoffExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional handoff exception as the handoff team keeps it.
    final class RegionalHandoffException {
        var code: String
        var name: String
        var batchSize: Int
        var quantity: Int
        var patientRef: String
        var endsAt: Int
        var status: RegionalHandoffExceptionStatus

        init(code: String, name: String, batchSize: Int, quantity: Int, patientRef: String, endsAt: Int, status: RegionalHandoffExceptionStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.quantity = quantity
            self.patientRef = patientRef
            self.endsAt = endsAt
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

        func canMoveTo(_ next: RegionalHandoffExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RegionalHandoffExceptionStatus.published || next == RegionalHandoffExceptionStatus.retired
            case .published:
                return next == RegionalHandoffExceptionStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalHandoffExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional handoff exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return ((Double(endsAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalHandoffException {
            return RegionalHandoffException(
                code: code,
                name: name,
                batchSize: batchSize,
                quantity: quantity,
                patientRef: patientRef,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional handoff exception in status created.
    static func newRegionalHandoffException(_ code: String, name: String) -> RegionalHandoffException {
        return RegionalHandoffException(
            code: code,
            name: name,
            batchSize: 0,
            quantity: 0,
            patientRef: "",
            endsAt: 0,
            status: RegionalHandoffExceptionStatus.created
        )
    }
}
