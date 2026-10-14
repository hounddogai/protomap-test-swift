import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form entry is in its life cycle.
    enum ConsentFormEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a consent form entry and its current status.
    final class ConsentFormEntry {
        var code: String
        var label: String
        var facility: String
        var minimum: Double
        var allergy: String
        var status: ConsentFormEntryStatus

        init(code: String, label: String, facility: String, minimum: Double, allergy: String, status: ConsentFormEntryStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.minimum = minimum
            self.allergy = allergy
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

        func canMoveTo(_ next: ConsentFormEntryStatus) -> Bool {
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

        func moveTo(_ next: ConsentFormEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> ConsentFormEntry {
            return ConsentFormEntry(
                code: code,
                label: label,
                facility: facility,
                minimum: minimum,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a consent form entry in status idle.
    static func newConsentFormEntry(_ code: String, label: String) -> ConsentFormEntry {
        return ConsentFormEntry(
            code: code,
            label: label,
            facility: "",
            minimum: 0.0,
            allergy: "",
            status: ConsentFormEntryStatus.idle
        )
    }
}
