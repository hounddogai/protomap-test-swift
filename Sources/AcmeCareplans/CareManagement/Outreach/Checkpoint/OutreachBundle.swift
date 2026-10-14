import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach bundle is in its life cycle.
    enum OutreachBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A outreach bundle as the outreach team keeps it.
    final class OutreachBundle {
        var code: String
        var title: String
        var allergy: String
        var tags: [String]
        var threshold: Double
        var description: String
        var windowDays: Int
        var status: OutreachBundleStatus

        init(code: String, title: String, allergy: String, tags: [String], threshold: Double, description: String, windowDays: Int, status: OutreachBundleStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.tags = tags
            self.threshold = threshold
            self.description = description
            self.windowDays = windowDays
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

        func canMoveTo(_ next: OutreachBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == OutreachBundleStatus.done || next == OutreachBundleStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == OutreachBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((threshold + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachBundle {
            return OutreachBundle(
                code: code,
                title: title,
                allergy: allergy,
                tags: tags,
                threshold: threshold,
                description: description,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach bundle in status new.
    static func newOutreachBundle(_ code: String, title: String) -> OutreachBundle {
        return OutreachBundle(
            code: code,
            title: title,
            allergy: "",
            tags: [],
            threshold: 0.0,
            description: "",
            windowDays: 0,
            status: OutreachBundleStatus.new
        )
    }
}
