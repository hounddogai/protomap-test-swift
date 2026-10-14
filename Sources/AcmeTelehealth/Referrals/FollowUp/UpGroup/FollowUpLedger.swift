import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up ledger is in its life cycle.
    enum FollowUpLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A follow up ledger. Its code is unique within a tenant.
    final class FollowUpLedger {
        var code: String
        var name: String
        var graceDays: Int
        var currency: String
        var source: String
        var allergy: String
        var label: String
        var maximum: Double
        var status: FollowUpLedgerStatus

        init(code: String, name: String, graceDays: Int, currency: String, source: String, allergy: String, label: String, maximum: Double, status: FollowUpLedgerStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.currency = currency
            self.source = source
            self.allergy = allergy
            self.label = label
            self.maximum = maximum
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

        func canMoveTo(_ next: FollowUpLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: FollowUpLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return (maximum * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpLedger {
            return FollowUpLedger(
                code: code,
                name: name,
                graceDays: graceDays,
                currency: currency,
                source: source,
                allergy: allergy,
                label: label,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a follow up ledger in status new.
    static func newFollowUpLedger(_ code: String, name: String) -> FollowUpLedger {
        return FollowUpLedger(
            code: code,
            name: name,
            graceDays: 0,
            currency: "",
            source: "",
            allergy: "",
            label: "",
            maximum: 0.0,
            status: FollowUpLedgerStatus.new
        )
    }
}
