import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive interaction score is in its life cycle.
    enum AdaptiveInteractionScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive interaction score, with what the planners need to act on it.
    final class AdaptiveInteractionScore {
        var code: String
        var label: String
        var attributes: [String: String]
        var copay: Double
        var durationMinutes: Int
        var floorValue: Double
        var visitMinutes: Int
        var status: AdaptiveInteractionScoreStatus

        init(code: String, label: String, attributes: [String: String], copay: Double, durationMinutes: Int, floorValue: Double, visitMinutes: Int, status: AdaptiveInteractionScoreStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: AdaptiveInteractionScoreStatus) -> Bool {
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
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveInteractionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive interaction score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func weightedTotal() -> Double {
            return (Double(durationMinutes) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInteractionScore {
            return AdaptiveInteractionScore(
                code: code,
                label: label,
                attributes: attributes,
                copay: copay,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive interaction score in status draft.
    static func newAdaptiveInteractionScore(_ code: String, label: String) -> AdaptiveInteractionScore {
        return AdaptiveInteractionScore(
            code: code,
            label: label,
            attributes: [:],
            copay: 0.0,
            durationMinutes: 0,
            floorValue: 0.0,
            visitMinutes: 0,
            status: AdaptiveInteractionScoreStatus.draft
        )
    }
}
