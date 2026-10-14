import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted witness record is in its life cycle.
    enum WeightedWitnessRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted witness record as the witness team keeps it.
    final class WeightedWitnessRecord {
        var code: String
        var label: String
        var patientRef: String
        var cost: Double
        var approved: Bool
        var threshold: Double
        var attributes: [String: String]
        var facility: String
        var notes: String
        var contactEmail: String
        var status: WeightedWitnessRecordStatus

        init(code: String, label: String, patientRef: String, cost: Double, approved: Bool, threshold: Double, attributes: [String: String], facility: String, notes: String, contactEmail: String, status: WeightedWitnessRecordStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.cost = cost
            self.approved = approved
            self.threshold = threshold
            self.attributes = attributes
            self.facility = facility
            self.notes = notes
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: WeightedWitnessRecordStatus) -> Bool {
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
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WeightedWitnessRecordStatus.draining || next == WeightedWitnessRecordStatus.stopped
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

        func moveTo(_ next: WeightedWitnessRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted witness record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedExposure() -> Double {
            return ((cost - threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedWitnessRecord {
            return WeightedWitnessRecord(
                code: code,
                label: label,
                patientRef: patientRef,
                cost: cost,
                approved: approved,
                threshold: threshold,
                attributes: attributes,
                facility: facility,
                notes: notes,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted witness record in status idle.
    static func newWeightedWitnessRecord(_ code: String, label: String) -> WeightedWitnessRecord {
        return WeightedWitnessRecord(
            code: code,
            label: label,
            patientRef: "",
            cost: 0.0,
            approved: false,
            threshold: 0.0,
            attributes: [:],
            facility: "",
            notes: "",
            contactEmail: "",
            status: WeightedWitnessRecordStatus.idle
        )
    }
}
