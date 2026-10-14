import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional priority target is in its life cycle.
    enum RegionalPriorityTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional priority target, with what the planners need to act on it.
    final class RegionalPriorityTarget {
        var code: String
        var label: String
        var phone: String
        var locale: String
        var category: String
        var priority: Int
        var sequence: Int
        var version: Int
        var status: RegionalPriorityTargetStatus

        init(code: String, label: String, phone: String, locale: String, category: String, priority: Int, sequence: Int, version: Int, status: RegionalPriorityTargetStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.locale = locale
            self.category = category
            self.priority = priority
            self.sequence = sequence
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalPriorityTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RegionalPriorityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional priority target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return ((Double(version) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalPriorityTarget {
            return RegionalPriorityTarget(
                code: code,
                label: label,
                phone: phone,
                locale: locale,
                category: category,
                priority: priority,
                sequence: sequence,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional priority target in status proposed.
    static func newRegionalPriorityTarget(_ code: String, label: String) -> RegionalPriorityTarget {
        return RegionalPriorityTarget(
            code: code,
            label: label,
            phone: "",
            locale: "",
            category: "",
            priority: 0,
            sequence: 0,
            version: 0,
            status: RegionalPriorityTargetStatus.proposed
        )
    }
}
