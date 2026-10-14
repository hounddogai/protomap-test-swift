import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling denial threshold is in its life cycle.
    enum RollingDenialThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rolling denial threshold, with what the planners need to act on it.
    final class RollingDenialThreshold {
        var code: String
        var title: String
        var score: Double
        var payer: String
        var source: String
        var allergy: String
        var tags: [String]
        var procedureCode: String
        var facility: String
        var status: RollingDenialThresholdStatus

        init(code: String, title: String, score: Double, payer: String, source: String, allergy: String, tags: [String], procedureCode: String, facility: String, status: RollingDenialThresholdStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.payer = payer
            self.source = source
            self.allergy = allergy
            self.tags = tags
            self.procedureCode = procedureCode
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingDenialThresholdStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingDenialThresholdStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RollingDenialThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling denial threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling denial threshold") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> RollingDenialThreshold {
            return RollingDenialThreshold(
                code: code,
                title: title,
                score: score,
                payer: payer,
                source: source,
                allergy: allergy,
                tags: tags,
                procedureCode: procedureCode,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling denial threshold in status planned.
    static func newRollingDenialThreshold(_ code: String, title: String) -> RollingDenialThreshold {
        return RollingDenialThreshold(
            code: code,
            title: title,
            score: 0.0,
            payer: "",
            source: "",
            allergy: "",
            tags: [],
            procedureCode: "",
            facility: "",
            status: RollingDenialThresholdStatus.planned
        )
    }
}
