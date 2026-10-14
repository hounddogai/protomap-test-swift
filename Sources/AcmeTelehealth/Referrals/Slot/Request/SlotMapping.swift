import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot mapping is in its life cycle.
    enum SlotMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a slot mapping and its current status.
    final class SlotMapping {
        var code: String
        var title: String
        var bed: String
        var maximum: Double
        var country: String
        var minimum: Double
        var weight: Double
        var limit: Int
        var patientRef: String
        var visible: Bool
        var status: SlotMappingStatus

        init(code: String, title: String, bed: String, maximum: Double, country: String, minimum: Double, weight: Double, limit: Int, patientRef: String, visible: Bool, status: SlotMappingStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.maximum = maximum
            self.country = country
            self.minimum = minimum
            self.weight = weight
            self.limit = limit
            self.patientRef = patientRef
            self.visible = visible
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

        func canMoveTo(_ next: SlotMappingStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SlotMappingStatus.reopened || next == SlotMappingStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
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
                return next == SlotMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((maximum + weight) * 100).rounded() / 100
        }

        func copyValue() -> SlotMapping {
            return SlotMapping(
                code: code,
                title: title,
                bed: bed,
                maximum: maximum,
                country: country,
                minimum: minimum,
                weight: weight,
                limit: limit,
                patientRef: patientRef,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a slot mapping in status open.
    static func newSlotMapping(_ code: String, title: String) -> SlotMapping {
        return SlotMapping(
            code: code,
            title: title,
            bed: "",
            maximum: 0.0,
            country: "",
            minimum: 0.0,
            weight: 0.0,
            limit: 0,
            patientRef: "",
            visible: false,
            status: SlotMappingStatus.`open`
        )
    }
}
