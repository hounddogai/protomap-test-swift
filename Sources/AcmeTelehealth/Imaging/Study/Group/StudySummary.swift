import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study summary is in its life cycle.
    enum StudySummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a study summary and its current status.
    final class StudySummary {
        var code: String
        var title: String
        var maximum: Double
        var ceiling: Double
        var channel: String
        var attributes: [String: String]
        var capacity: Int
        var description: String
        var status: StudySummaryStatus

        init(code: String, title: String, maximum: Double, ceiling: Double, channel: String, attributes: [String: String], capacity: Int, description: String, status: StudySummaryStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.ceiling = ceiling
            self.channel = channel
            self.attributes = attributes
            self.capacity = capacity
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudySummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == StudySummaryStatus.published || next == StudySummaryStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StudySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func netTotal() -> Double {
            return ((maximum + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StudySummary {
            return StudySummary(
                code: code,
                title: title,
                maximum: maximum,
                ceiling: ceiling,
                channel: channel,
                attributes: attributes,
                capacity: capacity,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a study summary in status created.
    static func newStudySummary(_ code: String, title: String) -> StudySummary {
        return StudySummary(
            code: code,
            title: title,
            maximum: 0.0,
            ceiling: 0.0,
            channel: "",
            attributes: [:],
            capacity: 0,
            description: "",
            status: StudySummaryStatus.created
        )
    }
}
