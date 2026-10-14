import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped specimen quota is in its life cycle.
    enum CappedSpecimenQuotaStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped specimen quota as the specimen team keeps it.
    final class CappedSpecimenQuota {
        var code: String
        var label: String
        var patientRef: String
        var segment: String
        var encounterID: String
        var attempts: Int
        var allergy: String
        var endsAt: Int
        var tags: [String]
        var discount: Double
        var visitMinutes: Int
        var status: CappedSpecimenQuotaStatus

        init(code: String, label: String, patientRef: String, segment: String, encounterID: String, attempts: Int, allergy: String, endsAt: Int, tags: [String], discount: Double, visitMinutes: Int, status: CappedSpecimenQuotaStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.segment = segment
            self.encounterID = encounterID
            self.attempts = attempts
            self.allergy = allergy
            self.endsAt = endsAt
            self.tags = tags
            self.discount = discount
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CappedSpecimenQuotaStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CappedSpecimenQuotaStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedSpecimenQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped specimen quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("capped specimen quota") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return (Double(visitMinutes) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedSpecimenQuota {
            return CappedSpecimenQuota(
                code: code,
                label: label,
                patientRef: patientRef,
                segment: segment,
                encounterID: encounterID,
                attempts: attempts,
                allergy: allergy,
                endsAt: endsAt,
                tags: tags,
                discount: discount,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped specimen quota in status open.
    static func newCappedSpecimenQuota(_ code: String, label: String) -> CappedSpecimenQuota {
        return CappedSpecimenQuota(
            code: code,
            label: label,
            patientRef: "",
            segment: "",
            encounterID: "",
            attempts: 0,
            allergy: "",
            endsAt: 0,
            tags: [],
            discount: 0.0,
            visitMinutes: 0,
            status: CappedSpecimenQuotaStatus.`open`
        )
    }
}
