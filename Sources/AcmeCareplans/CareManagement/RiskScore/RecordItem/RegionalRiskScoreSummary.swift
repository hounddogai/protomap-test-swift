import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional risk score summary is in its life cycle.
    enum RegionalRiskScoreSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional risk score summary. Its code is unique within a tenant.
    final class RegionalRiskScoreSummary {
        var code: String
        var title: String
        var capacity: Int
        var attributes: [String: String]
        var floorValue: Double
        var source: String
        var retries: Int
        var channel: String
        var country: String
        var status: RegionalRiskScoreSummaryStatus

        init(code: String, title: String, capacity: Int, attributes: [String: String], floorValue: Double, source: String, retries: Int, channel: String, country: String, status: RegionalRiskScoreSummaryStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.attributes = attributes
            self.floorValue = floorValue
            self.source = source
            self.retries = retries
            self.channel = channel
            self.country = country
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

        func canMoveTo(_ next: RegionalRiskScoreSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalRiskScoreSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalRiskScoreSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional risk score summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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
            return ((Double(capacity) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRiskScoreSummary {
            return RegionalRiskScoreSummary(
                code: code,
                title: title,
                capacity: capacity,
                attributes: attributes,
                floorValue: floorValue,
                source: source,
                retries: retries,
                channel: channel,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional risk score summary in status created.
    static func newRegionalRiskScoreSummary(_ code: String, title: String) -> RegionalRiskScoreSummary {
        return RegionalRiskScoreSummary(
            code: code,
            title: title,
            capacity: 0,
            attributes: [:],
            floorValue: 0.0,
            source: "",
            retries: 0,
            channel: "",
            country: "",
            status: RegionalRiskScoreSummaryStatus.created
        )
    }
}
