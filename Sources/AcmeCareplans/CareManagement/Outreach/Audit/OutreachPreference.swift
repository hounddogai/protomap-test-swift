import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach preference is in its life cycle.
    enum OutreachPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One outreach preference, with what the planners need to act on it.
    final class OutreachPreference {
        var code: String
        var title: String
        var ratio: Double
        var limit: Int
        var category: String
        var status: OutreachPreferenceStatus

        init(code: String, title: String, ratio: Double, limit: Int, category: String, status: OutreachPreferenceStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.limit = limit
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

        func canMoveTo(_ next: OutreachPreferenceStatus) -> Bool {
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
                return next == OutreachPreferenceStatus.done || next == OutreachPreferenceStatus.failed
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

        func moveTo(_ next: OutreachPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return (ratio * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> OutreachPreference {
            return OutreachPreference(
                code: code,
                title: title,
                ratio: ratio,
                limit: limit,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a outreach preference in status new.
    static func newOutreachPreference(_ code: String, title: String) -> OutreachPreference {
        return OutreachPreference(
            code: code,
            title: title,
            ratio: 0.0,
            limit: 0,
            category: "",
            status: OutreachPreferenceStatus.new
        )
    }
}
