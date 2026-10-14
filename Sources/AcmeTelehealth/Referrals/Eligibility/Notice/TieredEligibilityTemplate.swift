import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered eligibility template is in its life cycle.
    enum TieredEligibilityTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered eligibility template as the eligibility team keeps it.
    final class TieredEligibilityTemplate {
        var code: String
        var label: String
        var floorValue: Double
        var category: String
        var payer: String
        var tags: [String]
        var status: TieredEligibilityTemplateStatus

        init(code: String, label: String, floorValue: Double, category: String, payer: String, tags: [String], status: TieredEligibilityTemplateStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.category = category
            self.payer = payer
            self.tags = tags
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

        func canMoveTo(_ next: TieredEligibilityTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == TieredEligibilityTemplateStatus.done
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

        func moveTo(_ next: TieredEligibilityTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered eligibility template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> TieredEligibilityTemplate {
            return TieredEligibilityTemplate(
                code: code,
                label: label,
                floorValue: floorValue,
                category: category,
                payer: payer,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered eligibility template in status new.
    static func newTieredEligibilityTemplate(_ code: String, label: String) -> TieredEligibilityTemplate {
        return TieredEligibilityTemplate(
            code: code,
            label: label,
            floorValue: 0.0,
            category: "",
            payer: "",
            tags: [],
            status: TieredEligibilityTemplateStatus.new
        )
    }
}
