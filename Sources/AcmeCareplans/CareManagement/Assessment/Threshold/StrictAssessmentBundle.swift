import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict assessment bundle is in its life cycle.
    enum StrictAssessmentBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict assessment bundle as the assessment team keeps it.
    final class StrictAssessmentBundle {
        var code: String
        var label: String
        var approved: Bool
        var capacity: Int
        var channel: String
        var visible: Bool
        var attributes: [String: String]
        var score: Double
        var minimum: Double
        var ceiling: Double
        var externalRef: String
        var status: StrictAssessmentBundleStatus

        init(code: String, label: String, approved: Bool, capacity: Int, channel: String, visible: Bool, attributes: [String: String], score: Double, minimum: Double, ceiling: Double, externalRef: String, status: StrictAssessmentBundleStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.capacity = capacity
            self.channel = channel
            self.visible = visible
            self.attributes = attributes
            self.score = score
            self.minimum = minimum
            self.ceiling = ceiling
            self.externalRef = externalRef
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

        func canMoveTo(_ next: StrictAssessmentBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == StrictAssessmentBundleStatus.completed || next == StrictAssessmentBundleStatus.cancelled
            case .inProgress:
                return next == StrictAssessmentBundleStatus.completed
            case .completed:
                return next == StrictAssessmentBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictAssessmentBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict assessment bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func netTotal() -> Double {
            return ((minimum + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StrictAssessmentBundle {
            return StrictAssessmentBundle(
                code: code,
                label: label,
                approved: approved,
                capacity: capacity,
                channel: channel,
                visible: visible,
                attributes: attributes,
                score: score,
                minimum: minimum,
                ceiling: ceiling,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict assessment bundle in status planned.
    static func newStrictAssessmentBundle(_ code: String, label: String) -> StrictAssessmentBundle {
        return StrictAssessmentBundle(
            code: code,
            label: label,
            approved: false,
            capacity: 0,
            channel: "",
            visible: false,
            attributes: [:],
            score: 0.0,
            minimum: 0.0,
            ceiling: 0.0,
            externalRef: "",
            status: StrictAssessmentBundleStatus.planned
        )
    }
}
