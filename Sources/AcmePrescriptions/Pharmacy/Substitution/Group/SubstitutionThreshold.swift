import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution threshold is in its life cycle.
    enum SubstitutionThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A substitution threshold as the substitution team keeps it.
    final class SubstitutionThreshold {
        var code: String
        var label: String
        var durationMinutes: Int
        var source: String
        var contactEmail: String
        var status: SubstitutionThresholdStatus

        init(code: String, label: String, durationMinutes: Int, source: String, contactEmail: String, status: SubstitutionThresholdStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.source = source
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: SubstitutionThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == SubstitutionThresholdStatus.running
            case .queued:
                switch next {
                case .running:
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

        func moveTo(_ next: SubstitutionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> SubstitutionThreshold {
            return SubstitutionThreshold(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                source: source,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a substitution threshold in status new.
    static func newSubstitutionThreshold(_ code: String, label: String) -> SubstitutionThreshold {
        return SubstitutionThreshold(
            code: code,
            label: label,
            durationMinutes: 0,
            source: "",
            contactEmail: "",
            status: SubstitutionThresholdStatus.new
        )
    }
}
