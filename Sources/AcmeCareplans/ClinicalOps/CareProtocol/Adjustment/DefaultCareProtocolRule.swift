import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default care protocol rule is in its life cycle.
    enum DefaultCareProtocolRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default care protocol rule and its current status.
    final class DefaultCareProtocolRule {
        var code: String
        var name: String
        var bed: String
        var locale: String
        var ward: String
        var label: String
        var visitMinutes: Int
        var reviewer: String
        var version: Int
        var status: DefaultCareProtocolRuleStatus

        init(code: String, name: String, bed: String, locale: String, ward: String, label: String, visitMinutes: Int, reviewer: String, version: Int, status: DefaultCareProtocolRuleStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.locale = locale
            self.ward = ward
            self.label = label
            self.visitMinutes = visitMinutes
            self.reviewer = reviewer
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCareProtocolRuleStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultCareProtocolRuleStatus.warming
            case .warming:
                return next == DefaultCareProtocolRuleStatus.ready || next == DefaultCareProtocolRuleStatus.draining
            case .ready:
                return next == DefaultCareProtocolRuleStatus.draining || next == DefaultCareProtocolRuleStatus.stopped
            case .draining:
                return next == DefaultCareProtocolRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("default care protocol rule") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(version) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolRule {
            return DefaultCareProtocolRule(
                code: code,
                name: name,
                bed: bed,
                locale: locale,
                ward: ward,
                label: label,
                visitMinutes: visitMinutes,
                reviewer: reviewer,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default care protocol rule in status idle.
    static func newDefaultCareProtocolRule(_ code: String, name: String) -> DefaultCareProtocolRule {
        return DefaultCareProtocolRule(
            code: code,
            name: name,
            bed: "",
            locale: "",
            ward: "",
            label: "",
            visitMinutes: 0,
            reviewer: "",
            version: 0,
            status: DefaultCareProtocolRuleStatus.idle
        )
    }
}
