import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback authorization audit is in its life cycle.
    enum FallbackAuthorizationAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a fallback authorization audit and its current status.
    final class FallbackAuthorizationAudit {
        var code: String
        var name: String
        var budget: Double
        var maximum: Double
        var updatedAt: Int
        var archived: Bool
        var payer: String
        var score: Double
        var floorValue: Double
        var unit: String
        var currency: String
        var status: FallbackAuthorizationAuditStatus

        init(code: String, name: String, budget: Double, maximum: Double, updatedAt: Int, archived: Bool, payer: String, score: Double, floorValue: Double, unit: String, currency: String, status: FallbackAuthorizationAuditStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.maximum = maximum
            self.updatedAt = updatedAt
            self.archived = archived
            self.payer = payer
            self.score = score
            self.floorValue = floorValue
            self.unit = unit
            self.currency = currency
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

        func canMoveTo(_ next: FallbackAuthorizationAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackAuthorizationAuditStatus.done || next == FallbackAuthorizationAuditStatus.failed
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

        func moveTo(_ next: FallbackAuthorizationAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback authorization audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return (Double(updatedAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> FallbackAuthorizationAudit {
            return FallbackAuthorizationAudit(
                code: code,
                name: name,
                budget: budget,
                maximum: maximum,
                updatedAt: updatedAt,
                archived: archived,
                payer: payer,
                score: score,
                floorValue: floorValue,
                unit: unit,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback authorization audit in status new.
    static func newFallbackAuthorizationAudit(_ code: String, name: String) -> FallbackAuthorizationAudit {
        return FallbackAuthorizationAudit(
            code: code,
            name: name,
            budget: 0.0,
            maximum: 0.0,
            updatedAt: 0,
            archived: false,
            payer: "",
            score: 0.0,
            floorValue: 0.0,
            unit: "",
            currency: "",
            status: FallbackAuthorizationAuditStatus.new
        )
    }
}
