import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range adjustment is in its life cycle.
    enum ReferenceRangeAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One reference range adjustment, with what the planners need to act on it.
    final class ReferenceRangeAdjustment {
        var code: String
        var label: String
        var unit: String
        var currency: String
        var country: String
        var reviewer: String
        var archived: Bool
        var floorValue: Double
        var externalRef: String
        var status: ReferenceRangeAdjustmentStatus

        init(code: String, label: String, unit: String, currency: String, country: String, reviewer: String, archived: Bool, floorValue: Double, externalRef: String, status: ReferenceRangeAdjustmentStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.currency = currency
            self.country = country
            self.reviewer = reviewer
            self.archived = archived
            self.floorValue = floorValue
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ReferenceRangeAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ReferenceRangeAdjustmentStatus.published || next == ReferenceRangeAdjustmentStatus.retired
            case .published:
                return next == ReferenceRangeAdjustmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("reference range adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ReferenceRangeAdjustment {
            return ReferenceRangeAdjustment(
                code: code,
                label: label,
                unit: unit,
                currency: currency,
                country: country,
                reviewer: reviewer,
                archived: archived,
                floorValue: floorValue,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a reference range adjustment in status created.
    static func newReferenceRangeAdjustment(_ code: String, label: String) -> ReferenceRangeAdjustment {
        return ReferenceRangeAdjustment(
            code: code,
            label: label,
            unit: "",
            currency: "",
            country: "",
            reviewer: "",
            archived: false,
            floorValue: 0.0,
            externalRef: "",
            status: ReferenceRangeAdjustmentStatus.created
        )
    }
}
