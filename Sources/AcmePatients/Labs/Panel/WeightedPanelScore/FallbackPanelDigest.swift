import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback panel digest is in its life cycle.
    enum FallbackPanelDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback panel digest, with what the planners need to act on it.
    final class FallbackPanelDigest {
        var code: String
        var title: String
        var tags: [String]
        var dosageMg: Double
        var category: String
        var rate: Double
        var locale: String
        var summary: String
        var attributes: [String: String]
        var score: Double
        var channel: String
        var status: FallbackPanelDigestStatus

        init(code: String, title: String, tags: [String], dosageMg: Double, category: String, rate: Double, locale: String, summary: String, attributes: [String: String], score: Double, channel: String, status: FallbackPanelDigestStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.dosageMg = dosageMg
            self.category = category
            self.rate = rate
            self.locale = locale
            self.summary = summary
            self.attributes = attributes
            self.score = score
            self.channel = channel
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

        func canMoveTo(_ next: FallbackPanelDigestStatus) -> Bool {
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
                return next == FallbackPanelDigestStatus.done || next == FallbackPanelDigestStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackPanelDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackPanelDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback panel digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback panel digest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((rate - score) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPanelDigest {
            return FallbackPanelDigest(
                code: code,
                title: title,
                tags: tags,
                dosageMg: dosageMg,
                category: category,
                rate: rate,
                locale: locale,
                summary: summary,
                attributes: attributes,
                score: score,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback panel digest in status new.
    static func newFallbackPanelDigest(_ code: String, title: String) -> FallbackPanelDigest {
        return FallbackPanelDigest(
            code: code,
            title: title,
            tags: [],
            dosageMg: 0.0,
            category: "",
            rate: 0.0,
            locale: "",
            summary: "",
            attributes: [:],
            score: 0.0,
            channel: "",
            status: FallbackPanelDigestStatus.new
        )
    }
}
