import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol rule is in its life cycle.
    enum CareProtocolRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol rule as the care protocol team keeps it.
    final class CareProtocolRule {
        var code: String
        var name: String
        var visitMinutes: Int
        var phone: String
        var copay: Double
        var bed: String
        var attributes: [String: String]
        var status: CareProtocolRuleStatus

        init(code: String, name: String, visitMinutes: Int, phone: String, copay: Double, bed: String, attributes: [String: String], status: CareProtocolRuleStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.copay = copay
            self.bed = bed
            self.attributes = attributes
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

        func canMoveTo(_ next: CareProtocolRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolRuleStatus.done || next == CareProtocolRuleStatus.failed
            case .done:
                return next == CareProtocolRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return (copay * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRule {
            return CareProtocolRule(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                phone: phone,
                copay: copay,
                bed: bed,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol rule in status new.
    static func newCareProtocolRule(_ code: String, name: String) -> CareProtocolRule {
        return CareProtocolRule(
            code: code,
            name: name,
            visitMinutes: 0,
            phone: "",
            copay: 0.0,
            bed: "",
            attributes: [:],
            status: CareProtocolRuleStatus.new
        )
    }
}
