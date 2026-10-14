import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen ledger is in its life cycle.
    enum SpecimenLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One specimen ledger, with what the planners need to act on it.
    final class SpecimenLedger {
        var code: String
        var name: String
        var phone: String
        var reviewer: String
        var windowDays: Int
        var label: String
        var segment: String
        var status: SpecimenLedgerStatus

        init(code: String, name: String, phone: String, reviewer: String, windowDays: Int, label: String, segment: String, status: SpecimenLedgerStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.reviewer = reviewer
            self.windowDays = windowDays
            self.label = label
            self.segment = segment
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

        func canMoveTo(_ next: SpecimenLedgerStatus) -> Bool {
            switch status {
            case .idle:
                return next == SpecimenLedgerStatus.warming || next == SpecimenLedgerStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SpecimenLedgerStatus.draining || next == SpecimenLedgerStatus.stopped
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

        func moveTo(_ next: SpecimenLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("specimen ledger") \(code)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> SpecimenLedger {
            return SpecimenLedger(
                code: code,
                name: name,
                phone: phone,
                reviewer: reviewer,
                windowDays: windowDays,
                label: label,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a specimen ledger in status idle.
    static func newSpecimenLedger(_ code: String, name: String) -> SpecimenLedger {
        return SpecimenLedger(
            code: code,
            name: name,
            phone: "",
            reviewer: "",
            windowDays: 0,
            label: "",
            segment: "",
            status: SpecimenLedgerStatus.idle
        )
    }
}
