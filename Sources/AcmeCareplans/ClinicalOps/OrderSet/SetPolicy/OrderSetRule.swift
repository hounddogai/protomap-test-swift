import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set rule is in its life cycle.
    enum OrderSetRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a order set rule and its current status.
    final class OrderSetRule {
        var code: String
        var name: String
        var diagnosisCode: String
        var sequence: Int
        var endsAt: Int
        var attributes: [String: String]
        var title: String
        var updatedAt: Int
        var reviewer: String
        var maximum: Double
        var phone: String
        var status: OrderSetRuleStatus

        init(code: String, name: String, diagnosisCode: String, sequence: Int, endsAt: Int, attributes: [String: String], title: String, updatedAt: Int, reviewer: String, maximum: Double, phone: String, status: OrderSetRuleStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.endsAt = endsAt
            self.attributes = attributes
            self.title = title
            self.updatedAt = updatedAt
            self.reviewer = reviewer
            self.maximum = maximum
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetRuleStatus) -> Bool {
            switch status {
            case .planned:
                return next == OrderSetRuleStatus.inProgress || next == OrderSetRuleStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == OrderSetRuleStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: OrderSetRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func weightedExposure() -> Double {
            return (maximum * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetRule {
            return OrderSetRule(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                endsAt: endsAt,
                attributes: attributes,
                title: title,
                updatedAt: updatedAt,
                reviewer: reviewer,
                maximum: maximum,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set rule in status planned.
    static func newOrderSetRule(_ code: String, name: String) -> OrderSetRule {
        return OrderSetRule(
            code: code,
            name: name,
            diagnosisCode: "",
            sequence: 0,
            endsAt: 0,
            attributes: [:],
            title: "",
            updatedAt: 0,
            reviewer: "",
            maximum: 0.0,
            phone: "",
            status: OrderSetRuleStatus.planned
        )
    }
}
