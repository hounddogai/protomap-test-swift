import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual care protocol preference is in its life cycle.
    enum ManualCareProtocolPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One manual care protocol preference, with what the planners need to act on it.
    final class ManualCareProtocolPreference {
        var code: String
        var label: String
        var refills: Int
        var margin: Double
        var tags: [String]
        var windowDays: Int
        var name: String
        var ownerID: String
        var ratio: Double
        var dosageMg: Double
        var status: ManualCareProtocolPreferenceStatus

        init(code: String, label: String, refills: Int, margin: Double, tags: [String], windowDays: Int, name: String, ownerID: String, ratio: Double, dosageMg: Double, status: ManualCareProtocolPreferenceStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.margin = margin
            self.tags = tags
            self.windowDays = windowDays
            self.name = name
            self.ownerID = ownerID
            self.ratio = ratio
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ManualCareProtocolPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualCareProtocolPreferenceStatus.completed
            case .scheduled:
                return next == ManualCareProtocolPreferenceStatus.inProgress
            case .inProgress:
                return next == ManualCareProtocolPreferenceStatus.completed
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

        func moveTo(_ next: ManualCareProtocolPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((ratio - margin) * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolPreference {
            return ManualCareProtocolPreference(
                code: code,
                label: label,
                refills: refills,
                margin: margin,
                tags: tags,
                windowDays: windowDays,
                name: name,
                ownerID: ownerID,
                ratio: ratio,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual care protocol preference in status planned.
    static func newManualCareProtocolPreference(_ code: String, label: String) -> ManualCareProtocolPreference {
        return ManualCareProtocolPreference(
            code: code,
            label: label,
            refills: 0,
            margin: 0.0,
            tags: [],
            windowDays: 0,
            name: "",
            ownerID: "",
            ratio: 0.0,
            dosageMg: 0.0,
            status: ManualCareProtocolPreferenceStatus.planned
        )
    }
}
