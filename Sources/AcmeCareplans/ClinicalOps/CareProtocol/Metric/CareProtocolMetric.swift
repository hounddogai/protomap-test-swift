import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol metric is in its life cycle.
    enum CareProtocolMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One care protocol metric, with what the planners need to act on it.
    final class CareProtocolMetric {
        var code: String
        var name: String
        var specialty: String
        var bed: String
        var description: String
        var refills: Int
        var priority: Int
        var revision: Int
        var encounterID: String
        var status: CareProtocolMetricStatus

        init(code: String, name: String, specialty: String, bed: String, description: String, refills: Int, priority: Int, revision: Int, encounterID: String, status: CareProtocolMetricStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.bed = bed
            self.description = description
            self.refills = refills
            self.priority = priority
            self.revision = revision
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CareProtocolMetricStatus.reopened || next == CareProtocolMetricStatus.archived
            case .reopened:
                return next == CareProtocolMetricStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return (Double(refills) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolMetric {
            return CareProtocolMetric(
                code: code,
                name: name,
                specialty: specialty,
                bed: bed,
                description: description,
                refills: refills,
                priority: priority,
                revision: revision,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol metric in status open.
    static func newCareProtocolMetric(_ code: String, name: String) -> CareProtocolMetric {
        return CareProtocolMetric(
            code: code,
            name: name,
            specialty: "",
            bed: "",
            description: "",
            refills: 0,
            priority: 0,
            revision: 0,
            encounterID: "",
            status: CareProtocolMetricStatus.`open`
        )
    }
}
