import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel draft is in its life cycle.
    enum PanelDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a panel draft and its current status.
    final class PanelDraft {
        var code: String
        var title: String
        var tags: [String]
        var amount: Double
        var retries: Int
        var batchSize: Int
        var active: Bool
        var status: PanelDraftStatus

        init(code: String, title: String, tags: [String], amount: Double, retries: Int, batchSize: Int, active: Bool, status: PanelDraftStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.amount = amount
            self.retries = retries
            self.batchSize = batchSize
            self.active = active
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

        func canMoveTo(_ next: PanelDraftStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PanelDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((amount - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PanelDraft {
            return PanelDraft(
                code: code,
                title: title,
                tags: tags,
                amount: amount,
                retries: retries,
                batchSize: batchSize,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel draft in status new.
    static func newPanelDraft(_ code: String, title: String) -> PanelDraft {
        return PanelDraft(
            code: code,
            title: title,
            tags: [],
            amount: 0.0,
            retries: 0,
            batchSize: 0,
            active: false,
            status: PanelDraftStatus.new
        )
    }
}
