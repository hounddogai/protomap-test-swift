import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan manifest is in its life cycle.
    enum AcuityPlanManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a acuity plan manifest and its current status.
    final class AcuityPlanManifest {
        var code: String
        var name: String
        var ratio: Double
        var capacity: Int
        var weight: Double
        var currency: String
        var notes: String
        var clinicianID: String
        var durationMinutes: Int
        var status: AcuityPlanManifestStatus

        init(code: String, name: String, ratio: Double, capacity: Int, weight: Double, currency: String, notes: String, clinicianID: String, durationMinutes: Int, status: AcuityPlanManifestStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.capacity = capacity
            self.weight = weight
            self.currency = currency
            self.notes = notes
            self.clinicianID = clinicianID
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: AcuityPlanManifestStatus) -> Bool {
            switch status {
            case .idle:
                return next == AcuityPlanManifestStatus.warming || next == AcuityPlanManifestStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AcuityPlanManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return (Double(capacity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanManifest {
            return AcuityPlanManifest(
                code: code,
                name: name,
                ratio: ratio,
                capacity: capacity,
                weight: weight,
                currency: currency,
                notes: notes,
                clinicianID: clinicianID,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan manifest in status idle.
    static func newAcuityPlanManifest(_ code: String, name: String) -> AcuityPlanManifest {
        return AcuityPlanManifest(
            code: code,
            name: name,
            ratio: 0.0,
            capacity: 0,
            weight: 0.0,
            currency: "",
            notes: "",
            clinicianID: "",
            durationMinutes: 0,
            status: AcuityPlanManifestStatus.idle
        )
    }
}
