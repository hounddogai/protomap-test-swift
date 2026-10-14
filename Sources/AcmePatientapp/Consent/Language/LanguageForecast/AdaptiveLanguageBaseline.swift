import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive language baseline is in its life cycle.
    enum AdaptiveLanguageBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive language baseline. Its code is unique within a tenant.
    final class AdaptiveLanguageBaseline {
        var code: String
        var name: String
        var tags: [String]
        var ceiling: Double
        var clinicianID: String
        var specialty: String
        var pinned: Bool
        var capacity: Int
        var margin: Double
        var sequence: Int
        var status: AdaptiveLanguageBaselineStatus

        init(code: String, name: String, tags: [String], ceiling: Double, clinicianID: String, specialty: String, pinned: Bool, capacity: Int, margin: Double, sequence: Int, status: AdaptiveLanguageBaselineStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.ceiling = ceiling
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.pinned = pinned
            self.capacity = capacity
            self.margin = margin
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveLanguageBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveLanguageBaselineStatus.archived
            case .inReview:
                return next == AdaptiveLanguageBaselineStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveLanguageBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive language baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive language baseline") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(sequence) - margin) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveLanguageBaseline {
            return AdaptiveLanguageBaseline(
                code: code,
                name: name,
                tags: tags,
                ceiling: ceiling,
                clinicianID: clinicianID,
                specialty: specialty,
                pinned: pinned,
                capacity: capacity,
                margin: margin,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive language baseline in status open.
    static func newAdaptiveLanguageBaseline(_ code: String, name: String) -> AdaptiveLanguageBaseline {
        return AdaptiveLanguageBaseline(
            code: code,
            name: name,
            tags: [],
            ceiling: 0.0,
            clinicianID: "",
            specialty: "",
            pinned: false,
            capacity: 0,
            margin: 0.0,
            sequence: 0,
            status: AdaptiveLanguageBaselineStatus.`open`
        )
    }
}
