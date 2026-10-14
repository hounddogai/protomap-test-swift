import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive priority override is in its life cycle.
    enum AdaptivePriorityOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive priority override as the priority team keeps it.
    final class AdaptivePriorityOverride {
        var code: String
        var label: String
        var approved: Bool
        var pinned: Bool
        var expiresAt: Int
        var source: String
        var tags: [String]
        var ratio: Double
        var visible: Bool
        var patientRef: String
        var status: AdaptivePriorityOverrideStatus

        init(code: String, label: String, approved: Bool, pinned: Bool, expiresAt: Int, source: String, tags: [String], ratio: Double, visible: Bool, patientRef: String, status: AdaptivePriorityOverrideStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.source = source
            self.tags = tags
            self.ratio = ratio
            self.visible = visible
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptivePriorityOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptivePriorityOverrideStatus.pending || next == AdaptivePriorityOverrideStatus.active
            case .pending:
                return next == AdaptivePriorityOverrideStatus.closed
            case .active:
                return next == AdaptivePriorityOverrideStatus.suspended
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

        func moveTo(_ next: AdaptivePriorityOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive priority override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive priority override") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((Double(expiresAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePriorityOverride {
            return AdaptivePriorityOverride(
                code: code,
                label: label,
                approved: approved,
                pinned: pinned,
                expiresAt: expiresAt,
                source: source,
                tags: tags,
                ratio: ratio,
                visible: visible,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive priority override in status draft.
    static func newAdaptivePriorityOverride(_ code: String, label: String) -> AdaptivePriorityOverride {
        return AdaptivePriorityOverride(
            code: code,
            label: label,
            approved: false,
            pinned: false,
            expiresAt: 0,
            source: "",
            tags: [],
            ratio: 0.0,
            visible: false,
            patientRef: "",
            status: AdaptivePriorityOverrideStatus.draft
        )
    }
}
