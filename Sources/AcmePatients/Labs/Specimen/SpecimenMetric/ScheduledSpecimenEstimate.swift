import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled specimen estimate is in its life cycle.
    enum ScheduledSpecimenEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled specimen estimate, with what the planners need to act on it.
    final class ScheduledSpecimenEstimate {
        var code: String
        var label: String
        var discount: Double
        var maximum: Double
        var locale: String
        var ownerID: String
        var facility: String
        var approved: Bool
        var category: String
        var retries: Int
        var dosageMg: Double
        var status: ScheduledSpecimenEstimateStatus

        init(code: String, label: String, discount: Double, maximum: Double, locale: String, ownerID: String, facility: String, approved: Bool, category: String, retries: Int, dosageMg: Double, status: ScheduledSpecimenEstimateStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.maximum = maximum
            self.locale = locale
            self.ownerID = ownerID
            self.facility = facility
            self.approved = approved
            self.category = category
            self.retries = retries
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ScheduledSpecimenEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledSpecimenEstimateStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledSpecimenEstimateStatus.failed
            case .done:
                return next == ScheduledSpecimenEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledSpecimenEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled specimen estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((maximum - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledSpecimenEstimate {
            return ScheduledSpecimenEstimate(
                code: code,
                label: label,
                discount: discount,
                maximum: maximum,
                locale: locale,
                ownerID: ownerID,
                facility: facility,
                approved: approved,
                category: category,
                retries: retries,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled specimen estimate in status new.
    static func newScheduledSpecimenEstimate(_ code: String, label: String) -> ScheduledSpecimenEstimate {
        return ScheduledSpecimenEstimate(
            code: code,
            label: label,
            discount: 0.0,
            maximum: 0.0,
            locale: "",
            ownerID: "",
            facility: "",
            approved: false,
            category: "",
            retries: 0,
            dosageMg: 0.0,
            status: ScheduledSpecimenEstimateStatus.new
        )
    }
}
