import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study rule is in its life cycle.
    enum TieredStudyRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a tiered study rule and its current status.
    final class TieredStudyRule {
        var code: String
        var label: String
        var threshold: Double
        var windowDays: Int
        var timezone: String
        var visitMinutes: Int
        var contactEmail: String
        var weight: Double
        var phone: String
        var checksum: String
        var capacity: Int
        var status: TieredStudyRuleStatus

        init(code: String, label: String, threshold: Double, windowDays: Int, timezone: String, visitMinutes: Int, contactEmail: String, weight: Double, phone: String, checksum: String, capacity: Int, status: TieredStudyRuleStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.windowDays = windowDays
            self.timezone = timezone
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.weight = weight
            self.phone = phone
            self.checksum = checksum
            self.capacity = capacity
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

        func canMoveTo(_ next: TieredStudyRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredStudyRuleStatus.queued
            case .queued:
                return next == TieredStudyRuleStatus.failed
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: TieredStudyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveVolume() -> Double {
            return (threshold * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> TieredStudyRule {
            return TieredStudyRule(
                code: code,
                label: label,
                threshold: threshold,
                windowDays: windowDays,
                timezone: timezone,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                weight: weight,
                phone: phone,
                checksum: checksum,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered study rule in status new.
    static func newTieredStudyRule(_ code: String, label: String) -> TieredStudyRule {
        return TieredStudyRule(
            code: code,
            label: label,
            threshold: 0.0,
            windowDays: 0,
            timezone: "",
            visitMinutes: 0,
            contactEmail: "",
            weight: 0.0,
            phone: "",
            checksum: "",
            capacity: 0,
            status: TieredStudyRuleStatus.new
        )
    }
}
