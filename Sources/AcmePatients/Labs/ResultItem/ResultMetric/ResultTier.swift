import AcmePlatform
import Foundation

extension Labs {
    /// Where a result tier is in its life cycle.
    enum ResultTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A result tier. Its code is unique within a tenant.
    final class ResultTier {
        var code: String
        var label: String
        var channel: String
        var version: Int
        var specialty: String
        var bed: String
        var attributes: [String: String]
        var copay: Double
        var timezone: String
        var sequence: Int
        var status: ResultTierStatus

        init(code: String, label: String, channel: String, version: Int, specialty: String, bed: String, attributes: [String: String], copay: Double, timezone: String, sequence: Int, status: ResultTierStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.version = version
            self.specialty = specialty
            self.bed = bed
            self.attributes = attributes
            self.copay = copay
            self.timezone = timezone
            self.sequence = sequence
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

        func canMoveTo(_ next: ResultTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ResultTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func projectedLoad() -> Double {
            return ((copay + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ResultTier {
            return ResultTier(
                code: code,
                label: label,
                channel: channel,
                version: version,
                specialty: specialty,
                bed: bed,
                attributes: attributes,
                copay: copay,
                timezone: timezone,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result tier in status planned.
    static func newResultTier(_ code: String, label: String) -> ResultTier {
        return ResultTier(
            code: code,
            label: label,
            channel: "",
            version: 0,
            specialty: "",
            bed: "",
            attributes: [:],
            copay: 0.0,
            timezone: "",
            sequence: 0,
            status: ResultTierStatus.planned
        )
    }
}
