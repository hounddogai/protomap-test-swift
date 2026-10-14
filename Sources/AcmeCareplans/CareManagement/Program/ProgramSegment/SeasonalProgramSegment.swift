import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal program segment is in its life cycle.
    enum SeasonalProgramSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal program segment as the program team keeps it.
    final class SeasonalProgramSegment {
        var code: String
        var label: String
        var segment: String
        var weight: Double
        var contactEmail: String
        var rate: Double
        var category: String
        var source: String
        var encounterID: String
        var description: String
        var unit: String
        var status: SeasonalProgramSegmentStatus

        init(code: String, label: String, segment: String, weight: Double, contactEmail: String, rate: Double, category: String, source: String, encounterID: String, description: String, unit: String, status: SeasonalProgramSegmentStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.weight = weight
            self.contactEmail = contactEmail
            self.rate = rate
            self.category = category
            self.source = source
            self.encounterID = encounterID
            self.description = description
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalProgramSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalProgramSegmentStatus.rejected || next == SeasonalProgramSegmentStatus.withdrawn
            case .approved:
                return next == SeasonalProgramSegmentStatus.rejected || next == SeasonalProgramSegmentStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalProgramSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal program segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((weight - rate) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalProgramSegment {
            return SeasonalProgramSegment(
                code: code,
                label: label,
                segment: segment,
                weight: weight,
                contactEmail: contactEmail,
                rate: rate,
                category: category,
                source: source,
                encounterID: encounterID,
                description: description,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal program segment in status proposed.
    static func newSeasonalProgramSegment(_ code: String, label: String) -> SeasonalProgramSegment {
        return SeasonalProgramSegment(
            code: code,
            label: label,
            segment: "",
            weight: 0.0,
            contactEmail: "",
            rate: 0.0,
            category: "",
            source: "",
            encounterID: "",
            description: "",
            unit: "",
            status: SeasonalProgramSegmentStatus.proposed
        )
    }
}
