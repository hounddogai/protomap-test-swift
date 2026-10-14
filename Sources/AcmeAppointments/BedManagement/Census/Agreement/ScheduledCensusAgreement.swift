import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled census agreement is in its life cycle.
    enum ScheduledCensusAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled census agreement as the census team keeps it.
    final class ScheduledCensusAgreement {
        var code: String
        var name: String
        var procedureCode: String
        var diagnosisCode: String
        var quantity: Int
        var status: ScheduledCensusAgreementStatus

        init(code: String, name: String, procedureCode: String, diagnosisCode: String, quantity: Int, status: ScheduledCensusAgreementStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCensusAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledCensusAgreementStatus.warming || next == ScheduledCensusAgreementStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledCensusAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled census agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ScheduledCensusAgreement {
            return ScheduledCensusAgreement(
                code: code,
                name: name,
                procedureCode: procedureCode,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled census agreement in status idle.
    static func newScheduledCensusAgreement(_ code: String, name: String) -> ScheduledCensusAgreement {
        return ScheduledCensusAgreement(
            code: code,
            name: name,
            procedureCode: "",
            diagnosisCode: "",
            quantity: 0,
            status: ScheduledCensusAgreementStatus.idle
        )
    }
}
