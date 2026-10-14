import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional claim record is in its life cycle.
    enum RegionalClaimRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a regional claim record and its current status.
    final class RegionalClaimRecord {
        var code: String
        var name: String
        var specialty: String
        var phone: String
        var capacity: Int
        var amount: Double
        var sequence: Int
        var status: RegionalClaimRecordStatus

        init(code: String, name: String, specialty: String, phone: String, capacity: Int, amount: Double, sequence: Int, status: RegionalClaimRecordStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.phone = phone
            self.capacity = capacity
            self.amount = amount
            self.sequence = sequence
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

        func canMoveTo(_ next: RegionalClaimRecordStatus) -> Bool {
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
                case .done:
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
                return next == RegionalClaimRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalClaimRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional claim record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional claim record") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) + amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalClaimRecord {
            return RegionalClaimRecord(
                code: code,
                name: name,
                specialty: specialty,
                phone: phone,
                capacity: capacity,
                amount: amount,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional claim record in status new.
    static func newRegionalClaimRecord(_ code: String, name: String) -> RegionalClaimRecord {
        return RegionalClaimRecord(
            code: code,
            name: name,
            specialty: "",
            phone: "",
            capacity: 0,
            amount: 0.0,
            sequence: 0,
            status: RegionalClaimRecordStatus.new
        )
    }
}
