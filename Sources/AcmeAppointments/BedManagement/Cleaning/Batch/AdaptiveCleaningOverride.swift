import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning override is in its life cycle.
    enum AdaptiveCleaningOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a adaptive cleaning override and its current status.
    final class AdaptiveCleaningOverride {
        var code: String
        var title: String
        var locale: String
        var ownerID: String
        var score: Double
        var patientRef: String
        var status: AdaptiveCleaningOverrideStatus

        init(code: String, title: String, locale: String, ownerID: String, score: Double, patientRef: String, status: AdaptiveCleaningOverrideStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.ownerID = ownerID
            self.score = score
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptiveCleaningOverrideStatus) -> Bool {
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
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AdaptiveCleaningOverrideStatus.done
            case .done:
                return next == AdaptiveCleaningOverrideStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCleaningOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> AdaptiveCleaningOverride {
            return AdaptiveCleaningOverride(
                code: code,
                title: title,
                locale: locale,
                ownerID: ownerID,
                score: score,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive cleaning override in status new.
    static func newAdaptiveCleaningOverride(_ code: String, title: String) -> AdaptiveCleaningOverride {
        return AdaptiveCleaningOverride(
            code: code,
            title: title,
            locale: "",
            ownerID: "",
            score: 0.0,
            patientRef: "",
            status: AdaptiveCleaningOverrideStatus.new
        )
    }
}
