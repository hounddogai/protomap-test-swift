import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist agreement is in its life cycle.
    enum WorklistAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist agreement as the worklist team keeps it.
    final class WorklistAgreement {
        var code: String
        var name: String
        var visible: Bool
        var updatedAt: Int
        var source: String
        var cost: Double
        var diagnosisCode: String
        var unit: String
        var facility: String
        var status: WorklistAgreementStatus

        init(code: String, name: String, visible: Bool, updatedAt: Int, source: String, cost: Double, diagnosisCode: String, unit: String, facility: String, status: WorklistAgreementStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.updatedAt = updatedAt
            self.source = source
            self.cost = cost
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.facility = facility
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

        func canMoveTo(_ next: WorklistAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WorklistAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((cost - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistAgreement {
            return WorklistAgreement(
                code: code,
                name: name,
                visible: visible,
                updatedAt: updatedAt,
                source: source,
                cost: cost,
                diagnosisCode: diagnosisCode,
                unit: unit,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a worklist agreement in status proposed.
    static func newWorklistAgreement(_ code: String, name: String) -> WorklistAgreement {
        return WorklistAgreement(
            code: code,
            name: name,
            visible: false,
            updatedAt: 0,
            source: "",
            cost: 0.0,
            diagnosisCode: "",
            unit: "",
            facility: "",
            status: WorklistAgreementStatus.proposed
        )
    }
}
