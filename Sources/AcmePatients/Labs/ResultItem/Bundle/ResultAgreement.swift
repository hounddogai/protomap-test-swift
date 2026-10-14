import AcmePlatform
import Foundation

extension Labs {
    /// Where a result agreement is in its life cycle.
    enum ResultAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A result agreement. Its code is unique within a tenant.
    final class ResultAgreement {
        var code: String
        var title: String
        var capacity: Int
        var copay: Double
        var sequence: Int
        var active: Bool
        var visible: Bool
        var status: ResultAgreementStatus

        init(code: String, title: String, capacity: Int, copay: Double, sequence: Int, active: Bool, visible: Bool, status: ResultAgreementStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.copay = copay
            self.sequence = sequence
            self.active = active
            self.visible = visible
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

        func canMoveTo(_ next: ResultAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ResultAgreementStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ResultAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(sequence) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ResultAgreement {
            return ResultAgreement(
                code: code,
                title: title,
                capacity: capacity,
                copay: copay,
                sequence: sequence,
                active: active,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result agreement in status draft.
    static func newResultAgreement(_ code: String, title: String) -> ResultAgreement {
        return ResultAgreement(
            code: code,
            title: title,
            capacity: 0,
            copay: 0.0,
            sequence: 0,
            active: false,
            visible: false,
            status: ResultAgreementStatus.draft
        )
    }
}
