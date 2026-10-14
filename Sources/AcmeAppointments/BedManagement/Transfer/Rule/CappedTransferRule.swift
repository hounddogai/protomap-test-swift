import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped transfer rule is in its life cycle.
    enum CappedTransferRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a capped transfer rule and its current status.
    final class CappedTransferRule {
        var code: String
        var label: String
        var active: Bool
        var cost: Double
        var limit: Int
        var region: String
        var attempts: Int
        var locale: String
        var unit: String
        var status: CappedTransferRuleStatus

        init(code: String, label: String, active: Bool, cost: Double, limit: Int, region: String, attempts: Int, locale: String, unit: String, status: CappedTransferRuleStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.cost = cost
            self.limit = limit
            self.region = region
            self.attempts = attempts
            self.locale = locale
            self.unit = unit
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

        func canMoveTo(_ next: CappedTransferRuleStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedTransferRuleStatus.ready || next == CappedTransferRuleStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CappedTransferRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedTransferRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped transfer rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((cost + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> CappedTransferRule {
            return CappedTransferRule(
                code: code,
                label: label,
                active: active,
                cost: cost,
                limit: limit,
                region: region,
                attempts: attempts,
                locale: locale,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped transfer rule in status idle.
    static func newCappedTransferRule(_ code: String, label: String) -> CappedTransferRule {
        return CappedTransferRule(
            code: code,
            label: label,
            active: false,
            cost: 0.0,
            limit: 0,
            region: "",
            attempts: 0,
            locale: "",
            unit: "",
            status: CappedTransferRuleStatus.idle
        )
    }
}
