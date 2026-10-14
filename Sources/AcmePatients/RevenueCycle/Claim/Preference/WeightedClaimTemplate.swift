import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted claim template is in its life cycle.
    enum WeightedClaimTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted claim template and its current status.
    final class WeightedClaimTemplate {
        var code: String
        var label: String
        var summary: String
        var retries: Int
        var amount: Double
        var updatedAt: Int
        var approved: Bool
        var sequence: Int
        var payer: String
        var status: WeightedClaimTemplateStatus

        init(code: String, label: String, summary: String, retries: Int, amount: Double, updatedAt: Int, approved: Bool, sequence: Int, payer: String, status: WeightedClaimTemplateStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.retries = retries
            self.amount = amount
            self.updatedAt = updatedAt
            self.approved = approved
            self.sequence = sequence
            self.payer = payer
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

        func canMoveTo(_ next: WeightedClaimTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedClaimTemplateStatus.done || next == WeightedClaimTemplateStatus.failed
            case .queued:
                return next == WeightedClaimTemplateStatus.running || next == WeightedClaimTemplateStatus.failed
            case .running:
                return next == WeightedClaimTemplateStatus.done || next == WeightedClaimTemplateStatus.failed
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

        func moveTo(_ next: WeightedClaimTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted claim template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return (amount * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> WeightedClaimTemplate {
            return WeightedClaimTemplate(
                code: code,
                label: label,
                summary: summary,
                retries: retries,
                amount: amount,
                updatedAt: updatedAt,
                approved: approved,
                sequence: sequence,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted claim template in status new.
    static func newWeightedClaimTemplate(_ code: String, label: String) -> WeightedClaimTemplate {
        return WeightedClaimTemplate(
            code: code,
            label: label,
            summary: "",
            retries: 0,
            amount: 0.0,
            updatedAt: 0,
            approved: false,
            sequence: 0,
            payer: "",
            status: WeightedClaimTemplateStatus.new
        )
    }
}
