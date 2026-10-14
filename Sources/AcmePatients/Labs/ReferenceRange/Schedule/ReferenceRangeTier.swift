import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range tier is in its life cycle.
    enum ReferenceRangeTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A reference range tier. Its code is unique within a tenant.
    final class ReferenceRangeTier {
        var code: String
        var label: String
        var sequence: Int
        var ratio: Double
        var checksum: String
        var copay: Double
        var locale: String
        var cost: Double
        var priority: Int
        var ceiling: Double
        var contactEmail: String
        var status: ReferenceRangeTierStatus

        init(code: String, label: String, sequence: Int, ratio: Double, checksum: String, copay: Double, locale: String, cost: Double, priority: Int, ceiling: Double, contactEmail: String, status: ReferenceRangeTierStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.ratio = ratio
            self.checksum = checksum
            self.copay = copay
            self.locale = locale
            self.cost = cost
            self.priority = priority
            self.ceiling = ceiling
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ReferenceRangeTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferenceRangeTierStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ReferenceRangeTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("reference range tier") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((ratio + copay) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeTier {
            return ReferenceRangeTier(
                code: code,
                label: label,
                sequence: sequence,
                ratio: ratio,
                checksum: checksum,
                copay: copay,
                locale: locale,
                cost: cost,
                priority: priority,
                ceiling: ceiling,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a reference range tier in status idle.
    static func newReferenceRangeTier(_ code: String, label: String) -> ReferenceRangeTier {
        return ReferenceRangeTier(
            code: code,
            label: label,
            sequence: 0,
            ratio: 0.0,
            checksum: "",
            copay: 0.0,
            locale: "",
            cost: 0.0,
            priority: 0,
            ceiling: 0.0,
            contactEmail: "",
            status: ReferenceRangeTierStatus.idle
        )
    }
}
