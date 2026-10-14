import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge allocation is in its life cycle.
    enum ChargeAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One charge allocation, with what the planners need to act on it.
    final class ChargeAllocation {
        var code: String
        var label: String
        var revision: Int
        var category: String
        var weight: Double
        var clinicianID: String
        var ward: String
        var attempts: Int
        var timezone: String
        var country: String
        var status: ChargeAllocationStatus

        init(code: String, label: String, revision: Int, category: String, weight: Double, clinicianID: String, ward: String, attempts: Int, timezone: String, country: String, status: ChargeAllocationStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.category = category
            self.weight = weight
            self.clinicianID = clinicianID
            self.ward = ward
            self.attempts = attempts
            self.timezone = timezone
            self.country = country
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

        func canMoveTo(_ next: ChargeAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ChargeAllocationStatus.draining || next == ChargeAllocationStatus.stopped
            case .ready:
                return next == ChargeAllocationStatus.draining
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

        func moveTo(_ next: ChargeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((Double(revision) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeAllocation {
            return ChargeAllocation(
                code: code,
                label: label,
                revision: revision,
                category: category,
                weight: weight,
                clinicianID: clinicianID,
                ward: ward,
                attempts: attempts,
                timezone: timezone,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a charge allocation in status idle.
    static func newChargeAllocation(_ code: String, label: String) -> ChargeAllocation {
        return ChargeAllocation(
            code: code,
            label: label,
            revision: 0,
            category: "",
            weight: 0.0,
            clinicianID: "",
            ward: "",
            attempts: 0,
            timezone: "",
            country: "",
            status: ChargeAllocationStatus.idle
        )
    }
}
