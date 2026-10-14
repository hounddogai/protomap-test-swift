import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient revocation group is in its life cycle.
    enum LenientRevocationGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient revocation group as the revocation team keeps it.
    final class LenientRevocationGroup {
        var code: String
        var name: String
        var diagnosisCode: String
        var graceDays: Int
        var version: Int
        var capacity: Int
        var facility: String
        var threshold: Double
        var allergy: String
        var expiresAt: Int
        var weight: Double
        var status: LenientRevocationGroupStatus

        init(code: String, name: String, diagnosisCode: String, graceDays: Int, version: Int, capacity: Int, facility: String, threshold: Double, allergy: String, expiresAt: Int, weight: Double, status: LenientRevocationGroupStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.version = version
            self.capacity = capacity
            self.facility = facility
            self.threshold = threshold
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientRevocationGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientRevocationGroupStatus.scheduled || next == LenientRevocationGroupStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LenientRevocationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient revocation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(version) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientRevocationGroup {
            return LenientRevocationGroup(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                graceDays: graceDays,
                version: version,
                capacity: capacity,
                facility: facility,
                threshold: threshold,
                allergy: allergy,
                expiresAt: expiresAt,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient revocation group in status planned.
    static func newLenientRevocationGroup(_ code: String, name: String) -> LenientRevocationGroup {
        return LenientRevocationGroup(
            code: code,
            name: name,
            diagnosisCode: "",
            graceDays: 0,
            version: 0,
            capacity: 0,
            facility: "",
            threshold: 0.0,
            allergy: "",
            expiresAt: 0,
            weight: 0.0,
            status: LenientRevocationGroupStatus.planned
        )
    }
}
