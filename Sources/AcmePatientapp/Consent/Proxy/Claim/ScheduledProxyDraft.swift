import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled proxy draft is in its life cycle.
    enum ScheduledProxyDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled proxy draft, with what the planners need to act on it.
    final class ScheduledProxyDraft {
        var code: String
        var name: String
        var title: String
        var maximum: Double
        var refills: Int
        var ratio: Double
        var allergy: String
        var status: ScheduledProxyDraftStatus

        init(code: String, name: String, title: String, maximum: Double, refills: Int, ratio: Double, allergy: String, status: ScheduledProxyDraftStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.maximum = maximum
            self.refills = refills
            self.ratio = ratio
            self.allergy = allergy
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

        func canMoveTo(_ next: ScheduledProxyDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledProxyDraftStatus.failed
            case .queued:
                return next == ScheduledProxyDraftStatus.running || next == ScheduledProxyDraftStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledProxyDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledProxyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled proxy draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled proxy draft") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(refills) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProxyDraft {
            return ScheduledProxyDraft(
                code: code,
                name: name,
                title: title,
                maximum: maximum,
                refills: refills,
                ratio: ratio,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled proxy draft in status new.
    static func newScheduledProxyDraft(_ code: String, name: String) -> ScheduledProxyDraft {
        return ScheduledProxyDraft(
            code: code,
            name: name,
            title: "",
            maximum: 0.0,
            refills: 0,
            ratio: 0.0,
            allergy: "",
            status: ScheduledProxyDraftStatus.new
        )
    }
}
