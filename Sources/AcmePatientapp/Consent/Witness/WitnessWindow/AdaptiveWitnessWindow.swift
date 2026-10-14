import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive witness window is in its life cycle.
    enum AdaptiveWitnessWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive witness window. Its code is unique within a tenant.
    final class AdaptiveWitnessWindow {
        var code: String
        var label: String
        var bed: String
        var discount: Double
        var locale: String
        var archived: Bool
        var approved: Bool
        var ownerID: String
        var pinned: Bool
        var title: String
        var status: AdaptiveWitnessWindowStatus

        init(code: String, label: String, bed: String, discount: Double, locale: String, archived: Bool, approved: Bool, ownerID: String, pinned: Bool, title: String, status: AdaptiveWitnessWindowStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.discount = discount
            self.locale = locale
            self.archived = archived
            self.approved = approved
            self.ownerID = ownerID
            self.pinned = pinned
            self.title = title
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

        func canMoveTo(_ next: AdaptiveWitnessWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveWitnessWindowStatus.queued || next == AdaptiveWitnessWindowStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveWitnessWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive witness window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> AdaptiveWitnessWindow {
            return AdaptiveWitnessWindow(
                code: code,
                label: label,
                bed: bed,
                discount: discount,
                locale: locale,
                archived: archived,
                approved: approved,
                ownerID: ownerID,
                pinned: pinned,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive witness window in status new.
    static func newAdaptiveWitnessWindow(_ code: String, label: String) -> AdaptiveWitnessWindow {
        return AdaptiveWitnessWindow(
            code: code,
            label: label,
            bed: "",
            discount: 0.0,
            locale: "",
            archived: false,
            approved: false,
            ownerID: "",
            pinned: false,
            title: "",
            status: AdaptiveWitnessWindowStatus.new
        )
    }
}
