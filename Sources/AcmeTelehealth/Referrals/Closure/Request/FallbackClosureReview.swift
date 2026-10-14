import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback closure review is in its life cycle.
    enum FallbackClosureReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback closure review. Its code is unique within a tenant.
    final class FallbackClosureReview {
        var code: String
        var label: String
        var attributes: [String: String]
        var clinicianID: String
        var weight: Double
        var payer: String
        var limit: Int
        var budget: Double
        var unit: String
        var status: FallbackClosureReviewStatus

        init(code: String, label: String, attributes: [String: String], clinicianID: String, weight: Double, payer: String, limit: Int, budget: Double, unit: String, status: FallbackClosureReviewStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.clinicianID = clinicianID
            self.weight = weight
            self.payer = payer
            self.limit = limit
            self.budget = budget
            self.unit = unit
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

        func canMoveTo(_ next: FallbackClosureReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackClosureReviewStatus.queued || next == FallbackClosureReviewStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackClosureReviewStatus.done || next == FallbackClosureReviewStatus.failed
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

        func moveTo(_ next: FallbackClosureReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback closure review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func weightedLoad() -> Double {
            return (budget * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClosureReview {
            return FallbackClosureReview(
                code: code,
                label: label,
                attributes: attributes,
                clinicianID: clinicianID,
                weight: weight,
                payer: payer,
                limit: limit,
                budget: budget,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback closure review in status new.
    static func newFallbackClosureReview(_ code: String, label: String) -> FallbackClosureReview {
        return FallbackClosureReview(
            code: code,
            label: label,
            attributes: [:],
            clinicianID: "",
            weight: 0.0,
            payer: "",
            limit: 0,
            budget: 0.0,
            unit: "",
            status: FallbackClosureReviewStatus.new
        )
    }
}
