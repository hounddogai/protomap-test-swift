import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped inventory preference is in its life cycle.
    enum CappedInventoryPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped inventory preference as the inventory team keeps it.
    final class CappedInventoryPreference {
        var code: String
        var name: String
        var clinicianID: String
        var procedureCode: String
        var threshold: Double
        var phone: String
        var graceDays: Int
        var status: CappedInventoryPreferenceStatus

        init(code: String, name: String, clinicianID: String, procedureCode: String, threshold: Double, phone: String, graceDays: Int, status: CappedInventoryPreferenceStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.phone = phone
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CappedInventoryPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CappedInventoryPreferenceStatus.draining || next == CappedInventoryPreferenceStatus.stopped
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

        func moveTo(_ next: CappedInventoryPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped inventory preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedExposure() -> Double {
            return (Double(graceDays) * threshold * 100).rounded() / 100
        }

        func copyValue() -> CappedInventoryPreference {
            return CappedInventoryPreference(
                code: code,
                name: name,
                clinicianID: clinicianID,
                procedureCode: procedureCode,
                threshold: threshold,
                phone: phone,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped inventory preference in status idle.
    static func newCappedInventoryPreference(_ code: String, name: String) -> CappedInventoryPreference {
        return CappedInventoryPreference(
            code: code,
            name: name,
            clinicianID: "",
            procedureCode: "",
            threshold: 0.0,
            phone: "",
            graceDays: 0,
            status: CappedInventoryPreferenceStatus.idle
        )
    }
}
