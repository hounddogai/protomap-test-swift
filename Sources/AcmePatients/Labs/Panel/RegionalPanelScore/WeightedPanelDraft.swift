import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted panel draft is in its life cycle.
    enum WeightedPanelDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted panel draft as the panel team keeps it.
    final class WeightedPanelDraft {
        var code: String
        var name: String
        var specialty: String
        var label: String
        var version: Int
        var status: WeightedPanelDraftStatus

        init(code: String, name: String, specialty: String, label: String, version: Int, status: WeightedPanelDraftStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.label = label
            self.version = version
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

        func canMoveTo(_ next: WeightedPanelDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedPanelDraftStatus.failed
            case .queued:
                return next == WeightedPanelDraftStatus.done
            case .running:
                return next == WeightedPanelDraftStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: WeightedPanelDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted panel draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("weighted panel draft") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> WeightedPanelDraft {
            return WeightedPanelDraft(
                code: code,
                name: name,
                specialty: specialty,
                label: label,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted panel draft in status new.
    static func newWeightedPanelDraft(_ code: String, name: String) -> WeightedPanelDraft {
        return WeightedPanelDraft(
            code: code,
            name: name,
            specialty: "",
            label: "",
            version: 0,
            status: WeightedPanelDraftStatus.new
        )
    }
}
