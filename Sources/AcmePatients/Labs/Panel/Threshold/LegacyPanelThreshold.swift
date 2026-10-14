import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy panel threshold is in its life cycle.
    enum LegacyPanelThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy panel threshold and its current status.
    final class LegacyPanelThreshold {
        var code: String
        var title: String
        var notes: String
        var checksum: String
        var externalRef: String
        var score: Double
        var status: LegacyPanelThresholdStatus

        init(code: String, title: String, notes: String, checksum: String, externalRef: String, score: Double, status: LegacyPanelThresholdStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.checksum = checksum
            self.externalRef = externalRef
            self.score = score
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

        func canMoveTo(_ next: LegacyPanelThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyPanelThresholdStatus.active
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LegacyPanelThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyPanelThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy panel threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy panel threshold") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LegacyPanelThreshold {
            return LegacyPanelThreshold(
                code: code,
                title: title,
                notes: notes,
                checksum: checksum,
                externalRef: externalRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy panel threshold in status draft.
    static func newLegacyPanelThreshold(_ code: String, title: String) -> LegacyPanelThreshold {
        return LegacyPanelThreshold(
            code: code,
            title: title,
            notes: "",
            checksum: "",
            externalRef: "",
            score: 0.0,
            status: LegacyPanelThresholdStatus.draft
        )
    }
}
