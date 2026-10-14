import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction group is in its life cycle.
    enum InteractionGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A interaction group as the interaction team keeps it.
    final class InteractionGroup {
        var code: String
        var label: String
        var updatedAt: Int
        var priority: Int
        var region: String
        var locale: String
        var ceiling: Double
        var source: String
        var ward: String
        var status: InteractionGroupStatus

        init(code: String, label: String, updatedAt: Int, priority: Int, region: String, locale: String, ceiling: Double, source: String, ward: String, status: InteractionGroupStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.priority = priority
            self.region = region
            self.locale = locale
            self.ceiling = ceiling
            self.source = source
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == InteractionGroupStatus.reopened || next == InteractionGroupStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: InteractionGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("interaction group") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(priority) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> InteractionGroup {
            return InteractionGroup(
                code: code,
                label: label,
                updatedAt: updatedAt,
                priority: priority,
                region: region,
                locale: locale,
                ceiling: ceiling,
                source: source,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a interaction group in status open.
    static func newInteractionGroup(_ code: String, label: String) -> InteractionGroup {
        return InteractionGroup(
            code: code,
            label: label,
            updatedAt: 0,
            priority: 0,
            region: "",
            locale: "",
            ceiling: 0.0,
            source: "",
            ward: "",
            status: InteractionGroupStatus.`open`
        )
    }
}
