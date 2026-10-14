import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy courier cycle is in its life cycle.
    enum LegacyCourierCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy courier cycle as the courier team keeps it.
    final class LegacyCourierCycle {
        var code: String
        var title: String
        var phone: String
        var clinicianID: String
        var batchSize: Int
        var active: Bool
        var revision: Int
        var status: LegacyCourierCycleStatus

        init(code: String, title: String, phone: String, clinicianID: String, batchSize: Int, active: Bool, revision: Int, status: LegacyCourierCycleStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.active = active
            self.revision = revision
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

        func canMoveTo(_ next: LegacyCourierCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyCourierCycleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCourierCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy courier cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return (Double(batchSize) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCourierCycle {
            return LegacyCourierCycle(
                code: code,
                title: title,
                phone: phone,
                clinicianID: clinicianID,
                batchSize: batchSize,
                active: active,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy courier cycle in status proposed.
    static func newLegacyCourierCycle(_ code: String, title: String) -> LegacyCourierCycle {
        return LegacyCourierCycle(
            code: code,
            title: title,
            phone: "",
            clinicianID: "",
            batchSize: 0,
            active: false,
            revision: 0,
            status: LegacyCourierCycleStatus.proposed
        )
    }
}
