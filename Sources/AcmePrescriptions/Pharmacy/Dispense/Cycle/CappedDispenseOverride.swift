import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped dispense override is in its life cycle.
    enum CappedDispenseOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped dispense override. Its code is unique within a tenant.
    final class CappedDispenseOverride {
        var code: String
        var title: String
        var budget: Double
        var encounterID: String
        var procedureCode: String
        var retries: Int
        var status: CappedDispenseOverrideStatus

        init(code: String, title: String, budget: Double, encounterID: String, procedureCode: String, retries: Int, status: CappedDispenseOverrideStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.retries = retries
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

        func canMoveTo(_ next: CappedDispenseOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedDispenseOverrideStatus.warming || next == CappedDispenseOverrideStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CappedDispenseOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDispenseOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped dispense override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped dispense override") \(code)"
        }

        func adjustedVolume() -> Double {
            return (budget * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> CappedDispenseOverride {
            return CappedDispenseOverride(
                code: code,
                title: title,
                budget: budget,
                encounterID: encounterID,
                procedureCode: procedureCode,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped dispense override in status idle.
    static func newCappedDispenseOverride(_ code: String, title: String) -> CappedDispenseOverride {
        return CappedDispenseOverride(
            code: code,
            title: title,
            budget: 0.0,
            encounterID: "",
            procedureCode: "",
            retries: 0,
            status: CappedDispenseOverrideStatus.idle
        )
    }
}
