import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness notice is in its life cycle.
    enum WitnessNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness notice as the witness team keeps it.
    final class WitnessNotice {
        var code: String
        var name: String
        var score: Double
        var windowDays: Int
        var tags: [String]
        var discount: Double
        var description: String
        var attributes: [String: String]
        var attempts: Int
        var rate: Double
        var threshold: Double
        var status: WitnessNoticeStatus

        init(code: String, name: String, score: Double, windowDays: Int, tags: [String], discount: Double, description: String, attributes: [String: String], attempts: Int, rate: Double, threshold: Double, status: WitnessNoticeStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.windowDays = windowDays
            self.tags = tags
            self.discount = discount
            self.description = description
            self.attributes = attributes
            self.attempts = attempts
            self.rate = rate
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessNoticeStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == WitnessNoticeStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WitnessNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("witness notice") \(code)"
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

        func netExposure() -> Double {
            return (threshold * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> WitnessNotice {
            return WitnessNotice(
                code: code,
                name: name,
                score: score,
                windowDays: windowDays,
                tags: tags,
                discount: discount,
                description: description,
                attributes: attributes,
                attempts: attempts,
                rate: rate,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness notice in status idle.
    static func newWitnessNotice(_ code: String, name: String) -> WitnessNotice {
        return WitnessNotice(
            code: code,
            name: name,
            score: 0.0,
            windowDays: 0,
            tags: [],
            discount: 0.0,
            description: "",
            attributes: [:],
            attempts: 0,
            rate: 0.0,
            threshold: 0.0,
            status: WitnessNoticeStatus.idle
        )
    }
}
