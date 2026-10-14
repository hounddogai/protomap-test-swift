import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped language bundle is in its life cycle.
    enum CappedLanguageBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One capped language bundle, with what the planners need to act on it.
    final class CappedLanguageBundle {
        var code: String
        var label: String
        var score: Double
        var weight: Double
        var batchSize: Int
        var tags: [String]
        var visible: Bool
        var channel: String
        var status: CappedLanguageBundleStatus

        init(code: String, label: String, score: Double, weight: Double, batchSize: Int, tags: [String], visible: Bool, channel: String, status: CappedLanguageBundleStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.weight = weight
            self.batchSize = batchSize
            self.tags = tags
            self.visible = visible
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedLanguageBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == CappedLanguageBundleStatus.granted || next == CappedLanguageBundleStatus.expired
            case .granted:
                return next == CappedLanguageBundleStatus.revoked || next == CappedLanguageBundleStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedLanguageBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped language bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped language bundle") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return (score * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> CappedLanguageBundle {
            return CappedLanguageBundle(
                code: code,
                label: label,
                score: score,
                weight: weight,
                batchSize: batchSize,
                tags: tags,
                visible: visible,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped language bundle in status requested.
    static func newCappedLanguageBundle(_ code: String, label: String) -> CappedLanguageBundle {
        return CappedLanguageBundle(
            code: code,
            label: label,
            score: 0.0,
            weight: 0.0,
            batchSize: 0,
            tags: [],
            visible: false,
            channel: "",
            status: CappedLanguageBundleStatus.requested
        )
    }
}
