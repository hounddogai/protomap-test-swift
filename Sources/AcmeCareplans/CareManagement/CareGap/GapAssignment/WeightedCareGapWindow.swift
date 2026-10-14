import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted care gap window is in its life cycle.
    enum WeightedCareGapWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted care gap window. Its code is unique within a tenant.
    final class WeightedCareGapWindow {
        var code: String
        var label: String
        var revision: Int
        var rate: Double
        var channel: String
        var locale: String
        var minimum: Double
        var budget: Double
        var attributes: [String: String]
        var status: WeightedCareGapWindowStatus

        init(code: String, label: String, revision: Int, rate: Double, channel: String, locale: String, minimum: Double, budget: Double, attributes: [String: String], status: WeightedCareGapWindowStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.rate = rate
            self.channel = channel
            self.locale = locale
            self.minimum = minimum
            self.budget = budget
            self.attributes = attributes
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

        func canMoveTo(_ next: WeightedCareGapWindowStatus) -> Bool {
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
                return next == WeightedCareGapWindowStatus.resolved || next == WeightedCareGapWindowStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedCareGapWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care gap window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("weighted care gap window") \(code)"
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

        func adjustedLoad() -> Double {
            return ((rate + budget) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareGapWindow {
            return WeightedCareGapWindow(
                code: code,
                label: label,
                revision: revision,
                rate: rate,
                channel: channel,
                locale: locale,
                minimum: minimum,
                budget: budget,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted care gap window in status open.
    static func newWeightedCareGapWindow(_ code: String, label: String) -> WeightedCareGapWindow {
        return WeightedCareGapWindow(
            code: code,
            label: label,
            revision: 0,
            rate: 0.0,
            channel: "",
            locale: "",
            minimum: 0.0,
            budget: 0.0,
            attributes: [:],
            status: WeightedCareGapWindowStatus.`open`
        )
    }
}
