import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program ledger is in its life cycle.
    enum ProgramLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One program ledger, with what the planners need to act on it.
    final class ProgramLedger {
        var code: String
        var name: String
        var maximum: Double
        var region: String
        var contactEmail: String
        var attempts: Int
        var facility: String
        var visible: Bool
        var tags: [String]
        var status: ProgramLedgerStatus

        init(code: String, name: String, maximum: Double, region: String, contactEmail: String, attempts: Int, facility: String, visible: Bool, tags: [String], status: ProgramLedgerStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.region = region
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.facility = facility
            self.visible = visible
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ProgramLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((Double(attempts) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ProgramLedger {
            return ProgramLedger(
                code: code,
                name: name,
                maximum: maximum,
                region: region,
                contactEmail: contactEmail,
                attempts: attempts,
                facility: facility,
                visible: visible,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a program ledger in status new.
    static func newProgramLedger(_ code: String, name: String) -> ProgramLedger {
        return ProgramLedger(
            code: code,
            name: name,
            maximum: 0.0,
            region: "",
            contactEmail: "",
            attempts: 0,
            facility: "",
            visible: false,
            tags: [],
            status: ProgramLedgerStatus.new
        )
    }
}
