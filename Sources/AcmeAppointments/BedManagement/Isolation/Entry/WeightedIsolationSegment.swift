import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted isolation segment is in its life cycle.
    enum WeightedIsolationSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted isolation segment, with what the planners need to act on it.
    final class WeightedIsolationSegment {
        var code: String
        var name: String
        var approved: Bool
        var durationMinutes: Int
        var copay: Double
        var sequence: Int
        var specialty: String
        var currency: String
        var patientRef: String
        var quantity: Int
        var status: WeightedIsolationSegmentStatus

        init(code: String, name: String, approved: Bool, durationMinutes: Int, copay: Double, sequence: Int, specialty: String, currency: String, patientRef: String, quantity: Int, status: WeightedIsolationSegmentStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.sequence = sequence
            self.specialty = specialty
            self.currency = currency
            self.patientRef = patientRef
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedIsolationSegmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WeightedIsolationSegmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedIsolationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted isolation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return (Double(sequence) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedIsolationSegment {
            return WeightedIsolationSegment(
                code: code,
                name: name,
                approved: approved,
                durationMinutes: durationMinutes,
                copay: copay,
                sequence: sequence,
                specialty: specialty,
                currency: currency,
                patientRef: patientRef,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted isolation segment in status created.
    static func newWeightedIsolationSegment(_ code: String, name: String) -> WeightedIsolationSegment {
        return WeightedIsolationSegment(
            code: code,
            name: name,
            approved: false,
            durationMinutes: 0,
            copay: 0.0,
            sequence: 0,
            specialty: "",
            currency: "",
            patientRef: "",
            quantity: 0,
            status: WeightedIsolationSegmentStatus.created
        )
    }
}
