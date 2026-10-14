import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal substitution target is in its life cycle.
    enum SeasonalSubstitutionTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal substitution target. Its code is unique within a tenant.
    final class SeasonalSubstitutionTarget {
        var code: String
        var label: String
        var phone: String
        var facility: String
        var bed: String
        var endsAt: Int
        var notes: String
        var region: String
        var refills: Int
        var ownerID: String
        var encounterID: String
        var status: SeasonalSubstitutionTargetStatus

        init(code: String, label: String, phone: String, facility: String, bed: String, endsAt: Int, notes: String, region: String, refills: Int, ownerID: String, encounterID: String, status: SeasonalSubstitutionTargetStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.facility = facility
            self.bed = bed
            self.endsAt = endsAt
            self.notes = notes
            self.region = region
            self.refills = refills
            self.ownerID = ownerID
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SeasonalSubstitutionTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalSubstitutionTargetStatus.running || next == SeasonalSubstitutionTargetStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalSubstitutionTargetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSubstitutionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal substitution target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal substitution target") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSubstitutionTarget {
            return SeasonalSubstitutionTarget(
                code: code,
                label: label,
                phone: phone,
                facility: facility,
                bed: bed,
                endsAt: endsAt,
                notes: notes,
                region: region,
                refills: refills,
                ownerID: ownerID,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal substitution target in status new.
    static func newSeasonalSubstitutionTarget(_ code: String, label: String) -> SeasonalSubstitutionTarget {
        return SeasonalSubstitutionTarget(
            code: code,
            label: label,
            phone: "",
            facility: "",
            bed: "",
            endsAt: 0,
            notes: "",
            region: "",
            refills: 0,
            ownerID: "",
            encounterID: "",
            status: SeasonalSubstitutionTargetStatus.new
        )
    }
}
