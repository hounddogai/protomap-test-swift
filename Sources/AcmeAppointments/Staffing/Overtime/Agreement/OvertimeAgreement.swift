import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime agreement is in its life cycle.
    enum OvertimeAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a overtime agreement and its current status.
    final class OvertimeAgreement {
        var code: String
        var title: String
        var checksum: String
        var floorValue: Double
        var rate: Double
        var status: OvertimeAgreementStatus

        init(code: String, title: String, checksum: String, floorValue: Double, rate: Double, status: OvertimeAgreementStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.floorValue = floorValue
            self.rate = rate
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

        func canMoveTo(_ next: OvertimeAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == OvertimeAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime agreement") \(code)"
        }

        func projectedExposure() -> Double {
            return ((rate + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeAgreement {
            return OvertimeAgreement(
                code: code,
                title: title,
                checksum: checksum,
                floorValue: floorValue,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime agreement in status created.
    static func newOvertimeAgreement(_ code: String, title: String) -> OvertimeAgreement {
        return OvertimeAgreement(
            code: code,
            title: title,
            checksum: "",
            floorValue: 0.0,
            rate: 0.0,
            status: OvertimeAgreementStatus.created
        )
    }
}
