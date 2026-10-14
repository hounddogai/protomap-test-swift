import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted slot bundle is in its life cycle.
    enum WeightedSlotBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One weighted slot bundle, with what the planners need to act on it.
    final class WeightedSlotBundle {
        var code: String
        var title: String
        var payer: String
        var tags: [String]
        var ceiling: Double
        var score: Double
        var minimum: Double
        var copay: Double
        var channel: String
        var specialty: String
        var status: WeightedSlotBundleStatus

        init(code: String, title: String, payer: String, tags: [String], ceiling: Double, score: Double, minimum: Double, copay: Double, channel: String, specialty: String, status: WeightedSlotBundleStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.tags = tags
            self.ceiling = ceiling
            self.score = score
            self.minimum = minimum
            self.copay = copay
            self.channel = channel
            self.specialty = specialty
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

        func canMoveTo(_ next: WeightedSlotBundleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WeightedSlotBundleStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WeightedSlotBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSlotBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted slot bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((ceiling - score) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSlotBundle {
            return WeightedSlotBundle(
                code: code,
                title: title,
                payer: payer,
                tags: tags,
                ceiling: ceiling,
                score: score,
                minimum: minimum,
                copay: copay,
                channel: channel,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted slot bundle in status new.
    static func newWeightedSlotBundle(_ code: String, title: String) -> WeightedSlotBundle {
        return WeightedSlotBundle(
            code: code,
            title: title,
            payer: "",
            tags: [],
            ceiling: 0.0,
            score: 0.0,
            minimum: 0.0,
            copay: 0.0,
            channel: "",
            specialty: "",
            status: WeightedSlotBundleStatus.new
        )
    }
}
