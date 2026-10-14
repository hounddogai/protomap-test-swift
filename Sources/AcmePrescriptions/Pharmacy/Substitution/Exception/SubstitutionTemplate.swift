import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution template is in its life cycle.
    enum SubstitutionTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A substitution template as the substitution team keeps it.
    final class SubstitutionTemplate {
        var code: String
        var label: String
        var reviewer: String
        var quantity: Int
        var checksum: String
        var attributes: [String: String]
        var status: SubstitutionTemplateStatus

        init(code: String, label: String, reviewer: String, quantity: Int, checksum: String, attributes: [String: String], status: SubstitutionTemplateStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.quantity = quantity
            self.checksum = checksum
            self.attributes = attributes
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

        func canMoveTo(_ next: SubstitutionTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
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
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SubstitutionTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SubstitutionTemplate {
            return SubstitutionTemplate(
                code: code,
                label: label,
                reviewer: reviewer,
                quantity: quantity,
                checksum: checksum,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution template in status idle.
    static func newSubstitutionTemplate(_ code: String, label: String) -> SubstitutionTemplate {
        return SubstitutionTemplate(
            code: code,
            label: label,
            reviewer: "",
            quantity: 0,
            checksum: "",
            attributes: [:],
            status: SubstitutionTemplateStatus.idle
        )
    }
}
