import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census draft is in its life cycle.
    enum LegacyCensusDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy census draft as the census team keeps it.
    final class LegacyCensusDraft {
        var code: String
        var label: String
        var visible: Bool
        var budget: Double
        var reviewer: String
        var channel: String
        var threshold: Double
        var batchSize: Int
        var updatedAt: Int
        var attributes: [String: String]
        var status: LegacyCensusDraftStatus

        init(code: String, label: String, visible: Bool, budget: Double, reviewer: String, channel: String, threshold: Double, batchSize: Int, updatedAt: Int, attributes: [String: String], status: LegacyCensusDraftStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.budget = budget
            self.reviewer = reviewer
            self.channel = channel
            self.threshold = threshold
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCensusDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyCensusDraftStatus.suspended
            case .active:
                return next == LegacyCensusDraftStatus.suspended || next == LegacyCensusDraftStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyCensusDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
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

        func netExposure() -> Double {
            return ((Double(updatedAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCensusDraft {
            return LegacyCensusDraft(
                code: code,
                label: label,
                visible: visible,
                budget: budget,
                reviewer: reviewer,
                channel: channel,
                threshold: threshold,
                batchSize: batchSize,
                updatedAt: updatedAt,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy census draft in status draft.
    static func newLegacyCensusDraft(_ code: String, label: String) -> LegacyCensusDraft {
        return LegacyCensusDraft(
            code: code,
            label: label,
            visible: false,
            budget: 0.0,
            reviewer: "",
            channel: "",
            threshold: 0.0,
            batchSize: 0,
            updatedAt: 0,
            attributes: [:],
            status: LegacyCensusDraftStatus.draft
        )
    }
}
