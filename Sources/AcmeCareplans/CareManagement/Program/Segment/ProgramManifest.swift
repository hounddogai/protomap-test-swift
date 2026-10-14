import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program manifest is in its life cycle.
    enum ProgramManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A program manifest. Its code is unique within a tenant.
    final class ProgramManifest {
        var code: String
        var name: String
        var acuity: Int
        var amount: Double
        var locale: String
        var status: ProgramManifestStatus

        init(code: String, name: String, acuity: Int, amount: Double, locale: String, status: ProgramManifestStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.amount = amount
            self.locale = locale
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

        func canMoveTo(_ next: ProgramManifestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ProgramManifestStatus.cancelled
            case .inProgress:
                return next == ProgramManifestStatus.completed || next == ProgramManifestStatus.cancelled
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

        func moveTo(_ next: ProgramManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program manifest") \(code)"
        }

        func projectedVolume() -> Double {
            return ((amount - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramManifest {
            return ProgramManifest(
                code: code,
                name: name,
                acuity: acuity,
                amount: amount,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a program manifest in status planned.
    static func newProgramManifest(_ code: String, name: String) -> ProgramManifest {
        return ProgramManifest(
            code: code,
            name: name,
            acuity: 0,
            amount: 0.0,
            locale: "",
            status: ProgramManifestStatus.planned
        )
    }
}
