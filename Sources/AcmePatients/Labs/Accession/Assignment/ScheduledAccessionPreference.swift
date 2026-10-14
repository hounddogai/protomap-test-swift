import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled accession preference is in its life cycle.
    enum ScheduledAccessionPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled accession preference as the accession team keeps it.
    final class ScheduledAccessionPreference {
        var code: String
        var name: String
        var title: String
        var weight: Double
        var channel: String
        var procedureCode: String
        var checksum: String
        var budget: Double
        var label: String
        var region: String
        var status: ScheduledAccessionPreferenceStatus

        init(code: String, name: String, title: String, weight: Double, channel: String, procedureCode: String, checksum: String, budget: Double, label: String, region: String, status: ScheduledAccessionPreferenceStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.weight = weight
            self.channel = channel
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.budget = budget
            self.label = label
            self.region = region
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

        func canMoveTo(_ next: ScheduledAccessionPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledAccessionPreferenceStatus.ready || next == ScheduledAccessionPreferenceStatus.draining
            case .warming:
                return next == ScheduledAccessionPreferenceStatus.ready || next == ScheduledAccessionPreferenceStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledAccessionPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAccessionPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled accession preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled accession preference") \(code)"
        }

        func weightedLoad() -> Double {
            return ((budget + weight) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAccessionPreference {
            return ScheduledAccessionPreference(
                code: code,
                name: name,
                title: title,
                weight: weight,
                channel: channel,
                procedureCode: procedureCode,
                checksum: checksum,
                budget: budget,
                label: label,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled accession preference in status idle.
    static func newScheduledAccessionPreference(_ code: String, name: String) -> ScheduledAccessionPreference {
        return ScheduledAccessionPreference(
            code: code,
            name: name,
            title: "",
            weight: 0.0,
            channel: "",
            procedureCode: "",
            checksum: "",
            budget: 0.0,
            label: "",
            region: "",
            status: ScheduledAccessionPreferenceStatus.idle
        )
    }
}
