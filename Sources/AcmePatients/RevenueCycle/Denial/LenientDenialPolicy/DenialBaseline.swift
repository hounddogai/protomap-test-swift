import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial baseline is in its life cycle.
    enum DenialBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One denial baseline, with what the planners need to act on it.
    final class DenialBaseline {
        var code: String
        var label: String
        var summary: String
        var revision: Int
        var visible: Bool
        var capacity: Int
        var externalRef: String
        var maximum: Double
        var title: String
        var active: Bool
        var status: DenialBaselineStatus

        init(code: String, label: String, summary: String, revision: Int, visible: Bool, capacity: Int, externalRef: String, maximum: Double, title: String, active: Bool, status: DenialBaselineStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.revision = revision
            self.visible = visible
            self.capacity = capacity
            self.externalRef = externalRef
            self.maximum = maximum
            self.title = title
            self.active = active
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

        func canMoveTo(_ next: DenialBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: DenialBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveVolume() -> Double {
            return ((maximum - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DenialBaseline {
            return DenialBaseline(
                code: code,
                label: label,
                summary: summary,
                revision: revision,
                visible: visible,
                capacity: capacity,
                externalRef: externalRef,
                maximum: maximum,
                title: title,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a denial baseline in status created.
    static func newDenialBaseline(_ code: String, label: String) -> DenialBaseline {
        return DenialBaseline(
            code: code,
            label: label,
            summary: "",
            revision: 0,
            visible: false,
            capacity: 0,
            externalRef: "",
            maximum: 0.0,
            title: "",
            active: false,
            status: DenialBaselineStatus.created
        )
    }
}
