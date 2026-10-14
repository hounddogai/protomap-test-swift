import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure score is in its life cycle.
    enum ClosureScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One closure score, with what the planners need to act on it.
    final class ClosureScore {
        var code: String
        var title: String
        var createdAt: Int
        var attributes: [String: String]
        var ratio: Double
        var minimum: Double
        var patientRef: String
        var threshold: Double
        var tags: [String]
        var maximum: Double
        var status: ClosureScoreStatus

        init(code: String, title: String, createdAt: Int, attributes: [String: String], ratio: Double, minimum: Double, patientRef: String, threshold: Double, tags: [String], maximum: Double, status: ClosureScoreStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.attributes = attributes
            self.ratio = ratio
            self.minimum = minimum
            self.patientRef = patientRef
            self.threshold = threshold
            self.tags = tags
            self.maximum = maximum
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

        func canMoveTo(_ next: ClosureScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ClosureScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func effectiveVolume() -> Double {
            return (maximum * ratio * 100).rounded() / 100
        }

        func copyValue() -> ClosureScore {
            return ClosureScore(
                code: code,
                title: title,
                createdAt: createdAt,
                attributes: attributes,
                ratio: ratio,
                minimum: minimum,
                patientRef: patientRef,
                threshold: threshold,
                tags: tags,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a closure score in status draft.
    static func newClosureScore(_ code: String, title: String) -> ClosureScore {
        return ClosureScore(
            code: code,
            title: title,
            createdAt: 0,
            attributes: [:],
            ratio: 0.0,
            minimum: 0.0,
            patientRef: "",
            threshold: 0.0,
            tags: [],
            maximum: 0.0,
            status: ClosureScoreStatus.draft
        )
    }
}
