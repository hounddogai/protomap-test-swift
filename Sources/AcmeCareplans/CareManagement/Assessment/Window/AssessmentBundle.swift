import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment bundle is in its life cycle.
    enum AssessmentBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a assessment bundle and its current status.
    final class AssessmentBundle {
        var code: String
        var label: String
        var sequence: Int
        var archived: Bool
        var channel: String
        var revision: Int
        var ceiling: Double
        var category: String
        var status: AssessmentBundleStatus

        init(code: String, label: String, sequence: Int, archived: Bool, channel: String, revision: Int, ceiling: Double, category: String, status: AssessmentBundleStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.archived = archived
            self.channel = channel
            self.revision = revision
            self.ceiling = ceiling
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == AssessmentBundleStatus.queued || next == AssessmentBundleStatus.running
            case .queued:
                return next == AssessmentBundleStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AssessmentBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(sequence) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentBundle {
            return AssessmentBundle(
                code: code,
                label: label,
                sequence: sequence,
                archived: archived,
                channel: channel,
                revision: revision,
                ceiling: ceiling,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a assessment bundle in status new.
    static func newAssessmentBundle(_ code: String, label: String) -> AssessmentBundle {
        return AssessmentBundle(
            code: code,
            label: label,
            sequence: 0,
            archived: false,
            channel: "",
            revision: 0,
            ceiling: 0.0,
            category: "",
            status: AssessmentBundleStatus.new
        )
    }
}
