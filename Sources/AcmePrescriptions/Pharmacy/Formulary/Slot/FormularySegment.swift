import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary segment is in its life cycle.
    enum FormularySegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One formulary segment, with what the planners need to act on it.
    final class FormularySegment {
        var code: String
        var label: String
        var unit: String
        var encounterID: String
        var specialty: String
        var cost: Double
        var currency: String
        var approved: Bool
        var version: Int
        var status: FormularySegmentStatus

        init(code: String, label: String, unit: String, encounterID: String, specialty: String, cost: Double, currency: String, approved: Bool, version: Int, status: FormularySegmentStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.encounterID = encounterID
            self.specialty = specialty
            self.cost = cost
            self.currency = currency
            self.approved = approved
            self.version = version
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

        func canMoveTo(_ next: FormularySegmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FormularySegmentStatus.draining || next == FormularySegmentStatus.stopped
            case .draining:
                return next == FormularySegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("formulary segment") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(version) + cost) * 100).rounded() / 100
        }

        func copyValue() -> FormularySegment {
            return FormularySegment(
                code: code,
                label: label,
                unit: unit,
                encounterID: encounterID,
                specialty: specialty,
                cost: cost,
                currency: currency,
                approved: approved,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a formulary segment in status idle.
    static func newFormularySegment(_ code: String, label: String) -> FormularySegment {
        return FormularySegment(
            code: code,
            label: label,
            unit: "",
            encounterID: "",
            specialty: "",
            cost: 0.0,
            currency: "",
            approved: false,
            version: 0,
            status: FormularySegmentStatus.idle
        )
    }
}
