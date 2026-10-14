import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program record is in its life cycle.
    enum ProgramRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A program record. Its code is unique within a tenant.
    final class ProgramRecord {
        var code: String
        var label: String
        var revision: Int
        var contactEmail: String
        var source: String
        var amount: Double
        var status: ProgramRecordStatus

        init(code: String, label: String, revision: Int, contactEmail: String, source: String, amount: Double, status: ProgramRecordStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.contactEmail = contactEmail
            self.source = source
            self.amount = amount
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

        func canMoveTo(_ next: ProgramRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ProgramRecordStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ProgramRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return ((amount - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramRecord {
            return ProgramRecord(
                code: code,
                label: label,
                revision: revision,
                contactEmail: contactEmail,
                source: source,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a program record in status idle.
    static func newProgramRecord(_ code: String, label: String) -> ProgramRecord {
        return ProgramRecord(
            code: code,
            label: label,
            revision: 0,
            contactEmail: "",
            source: "",
            amount: 0.0,
            status: ProgramRecordStatus.idle
        )
    }
}
