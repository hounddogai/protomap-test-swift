import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board exception is in its life cycle.
    enum BedBoardExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A bed board exception. Its code is unique within a tenant.
    final class BedBoardException {
        var code: String
        var label: String
        var attempts: Int
        var visitMinutes: Int
        var unit: String
        var dosageMg: Double
        var source: String
        var status: BedBoardExceptionStatus

        init(code: String, label: String, attempts: Int, visitMinutes: Int, unit: String, dosageMg: Double, source: String, status: BedBoardExceptionStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.unit = unit
            self.dosageMg = dosageMg
            self.source = source
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

        func canMoveTo(_ next: BedBoardExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BedBoardExceptionStatus.stopped
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

        func moveTo(_ next: BedBoardExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("bed board exception") \(code)"
        }

        func netValue() -> Double {
            return (Double(attempts) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardException {
            return BedBoardException(
                code: code,
                label: label,
                attempts: attempts,
                visitMinutes: visitMinutes,
                unit: unit,
                dosageMg: dosageMg,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a bed board exception in status idle.
    static func newBedBoardException(_ code: String, label: String) -> BedBoardException {
        return BedBoardException(
            code: code,
            label: label,
            attempts: 0,
            visitMinutes: 0,
            unit: "",
            dosageMg: 0.0,
            source: "",
            status: BedBoardExceptionStatus.idle
        )
    }
}
